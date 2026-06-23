import 'package:abyss_relic/models/affix_config.dart';
import 'package:abyss_relic/models/data_file_meta.dart';
import 'package:abyss_relic/models/equipment_instance.dart';
import 'package:abyss_relic/models/loaded_data_file.dart';
import 'package:abyss_relic/systems/build/build_service.dart';
import 'package:abyss_relic/systems/config/game_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'BuildService identifies poison shadow builds from class skills and gear',
      () {
    final service = BuildService(_database());

    final assessment = service.assess(
      classId: 'exile',
      skillIds: const ['toxic_slash'],
      equipment: [
        _equipment(
          templateId: 'rusted_blade',
          affixId: 'aff_poison_damage',
        ),
      ],
    );

    expect(assessment.buildId, 'poison_shadow');
    expect(assessment.isMixed, isFalse);
    expect(assessment.tagWeights['poison'], greaterThan(0));
    expect(assessment.tagWeights['shadow'], greaterThan(0));
  });

  test('BuildService identifies summon undead builds', () {
    final service = BuildService(_database());

    final assessment = service.assess(
      classId: 'necrospeaker',
      skillIds: const ['bone_servant'],
      equipment: const [],
    );

    expect(assessment.buildId, 'summon_undead');
    expect(assessment.isMixed, isFalse);
    expect(assessment.tagWeights['summon'], greaterThan(0));
    expect(assessment.tagWeights['undead'], greaterThan(0));
  });

  test('BuildService keeps unclear tag sets as mixed', () {
    final service = BuildService(_database());

    final assessment = service.assess(
      classId: 'wanderer',
      skillIds: const ['utility_step'],
      equipment: const [],
    );

    expect(assessment.buildId, 'mixed');
    expect(assessment.isMixed, isTrue);
    expect(assessment.label, 'Mixed Build');
  });
}

EquipmentInstance _equipment({
  required String templateId,
  required String affixId,
}) {
  return EquipmentInstance(
    instanceId: 'eq_$templateId',
    templateId: templateId,
    qualityId: 'rare',
    level: 5,
    createdAt: DateTime.utc(2026, 1, 1),
    rolledBaseStats: const [],
    rolledAffixes: [
      RolledAffix(
        affixId: affixId,
        rollValue: 0.12,
        exclusiveGroup: 'element_damage',
      ),
    ],
  );
}

GameDatabase _database() {
  return GameDatabase.fromFiles([
    _file('assets/data/classes.json', {
      'schemaVersion': 1,
      'classes': [
        {
          'id': 'exile',
          'name': 'Exile',
          'tags': ['poison', 'bleed', 'shadow', 'low_hp'],
        },
        {
          'id': 'necrospeaker',
          'name': 'Necrospeaker',
          'tags': ['summon', 'curse', 'shield', 'undead'],
        },
        {
          'id': 'wanderer',
          'name': 'Wanderer',
          'tags': ['utility'],
        },
      ],
    }),
    _file('assets/data/skills.json', {
      'schemaVersion': 1,
      'skills': [
        {
          'id': 'toxic_slash',
          'name': 'Toxic Slash',
          'tags': ['poison', 'shadow'],
        },
        {
          'id': 'bone_servant',
          'name': 'Bone Servant',
          'tags': ['summon', 'undead'],
        },
        {
          'id': 'utility_step',
          'name': 'Utility Step',
          'tags': ['mobility'],
        },
      ],
    }),
    _file('assets/data/equipment_templates.json', {
      'schemaVersion': 1,
      'equipment_templates': [
        {
          'id': 'rusted_blade',
          'name': 'Rusted Blade',
          'affixRules': {
            'prefixMin': 0,
            'prefixMax': 1,
            'suffixMin': 0,
            'suffixMax': 1,
            'allowedTags': ['poison', 'shadow'],
          },
        },
      ],
    }),
    _file('assets/data/affixes.json', {
      'schemaVersion': 1,
      'affixes': [
        {
          'id': 'aff_poison_damage',
          'name': 'Poison Damage',
          'type': 'element',
          'tags': ['poison'],
          'minLevel': 1,
          'weight': 100,
        },
      ],
    }),
  ]);
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
