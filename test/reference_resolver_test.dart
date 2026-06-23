import 'package:abyss_relic/models/config_validation_error.dart';
import 'package:abyss_relic/models/data_file_meta.dart';
import 'package:abyss_relic/models/loaded_data_file.dart';
import 'package:abyss_relic/systems/config/game_database.dart';
import 'package:abyss_relic/systems/config/reference_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ReferenceResolver accepts valid cross-table references', () {
    final database = GameDatabase.fromFiles([
      _file('assets/data/classes.json', {
        'schemaVersion': 1,
        'classes': [
          {'id': 'exile', 'name': '流放者'},
        ],
      }),
      _file('assets/data/skills.json', {
        'schemaVersion': 1,
        'skills': [
          {
            'id': 'toxic_slash',
            'name': '毒刃',
            'classId': 'exile',
            'effects': [
              {
                'effectId': 'deal_damage',
                'params': {'damageType': 'poison'},
              },
            ],
          },
        ],
      }),
      _file('assets/data/equipment_templates.json', {
        'schemaVersion': 1,
        'equipment_templates': [
          {
            'id': 'rusted_blade',
            'name': '锈蚀短刃',
            'allowedClasses': ['exile'],
          },
        ],
      }),
      _file('assets/data/drop_pools.json', {
        'schemaVersion': 1,
        'drop_pools': [
          {
            'id': 'drop_chapter_1',
            'name': '第1章掉落',
            'entries': [
              {'type': 'equipment', 'refId': 'rusted_blade'},
            ],
          },
        ],
      }),
    ]);

    final errors = const ReferenceResolver().check(database);

    expect(errors, isEmpty);
  });

  test('ReferenceResolver reports invalid class references', () {
    final database = GameDatabase.fromFiles([
      _file('assets/data/classes.json', {
        'schemaVersion': 1,
        'classes': [
          {'id': 'exile', 'name': '流放者'},
        ],
      }),
      _file('assets/data/skills.json', {
        'schemaVersion': 1,
        'skills': [
          {'id': 'bad_skill', 'name': '坏技能', 'classId': 'missing_class'},
        ],
      }),
    ]);

    final errors = const ReferenceResolver().check(database);

    expect(errors.single.code, ConfigValidationCode.invalidReference);
    expect(errors.single.field, 'classId');
    expect(errors.single.recordId, 'bad_skill');
  });

  test('ReferenceResolver reports invalid drop pool references', () {
    final database = GameDatabase.fromFiles([
      _file('assets/data/drop_pools.json', {
        'schemaVersion': 1,
        'drop_pools': [
          {
            'id': 'drop_broken',
            'name': '坏掉落',
            'entries': [
              {'type': 'equipment', 'refId': 'missing_item'},
            ],
          },
        ],
      }),
    ]);

    final errors = const ReferenceResolver().check(database);

    expect(errors.single.code, ConfigValidationCode.invalidReference);
    expect(errors.single.field, 'entries.refId');
    expect(errors.single.recordId, 'drop_broken');
  });

  test('ReferenceResolver reports unknown effect ids', () {
    final database = GameDatabase.fromFiles([
      _file('assets/data/affixes.json', {
        'schemaVersion': 1,
        'affixes': [
          {
            'id': 'aff_weird',
            'name': '怪异词缀',
            'effect': {'effectId': 'missing_effect', 'params': {}},
          },
        ],
      }),
    ]);

    final errors = const ReferenceResolver().check(database);

    expect(errors.single.code, ConfigValidationCode.invalidReference);
    expect(errors.single.field, 'effect.effectId');
    expect(errors.single.recordId, 'aff_weird');
  });
}

LoadedDataFile _file(String assetPath, Map<String, Object?> json) {
  return LoadedDataFile(
    meta: DataFileMeta(
      assetPath: assetPath,
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      recordCount: 1,
      topLevelKeys: json.keys.toList(),
    ),
    json: json,
  );
}
