import 'package:abyss_relic/models/data_file_meta.dart';
import 'package:abyss_relic/models/equipment_template.dart';
import 'package:abyss_relic/models/loaded_data_file.dart';
import 'package:abyss_relic/systems/config/game_database.dart';
import 'package:abyss_relic/systems/equipment/equipment_template_service.dart';
import 'package:abyss_relic/systems/equipment/quality_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EquipmentSlot exposes the expected twelve equipment slots', () {
    expect(EquipmentSlot.values.map((slot) => slot.id), [
      'main_weapon',
      'offhand',
      'helmet',
      'chest',
      'gloves',
      'boots',
      'belt',
      'amulet',
      'ring_1',
      'ring_2',
      'relic',
      'soul_core',
    ]);
  });

  test('QualityService loads all eight quality configs', () {
    final qualities = QualityService(_databaseWithEquipment()).listQualities();

    expect(qualities.map((quality) => quality.id), [
      'normal',
      'magic',
      'rare',
      'epic',
      'legendary',
      'mythic',
      'abyss',
      'forbidden',
    ]);
    expect(
      QualityService(_databaseWithEquipment())
          .requireQuality('legendary')
          .specialEffectChance,
      0.15,
    );
  });

  test('EquipmentTemplateService parses configured templates', () {
    final service = EquipmentTemplateService(_databaseWithEquipment());

    final template = service.requireTemplate('rusted_blade');

    expect(template.id, 'rusted_blade');
    expect(template.slot, EquipmentSlot.mainWeapon);
    expect(template.allowedClasses, ['exile']);
    expect(template.qualityPool, ['normal', 'magic', 'rare']);
    expect(template.baseStats.single.stat, 'attack');
    expect(template.affixRules.allowedTags, ['poison', 'shadow']);
  });

  test('EquipmentTemplateService rejects missing templates', () {
    final service = EquipmentTemplateService(_databaseWithEquipment());

    expect(
      () => service.requireTemplate('missing_template'),
      throwsA(isA<StateError>()),
    );
  });
}

GameDatabase _databaseWithEquipment() {
  return GameDatabase.fromFiles([
    LoadedDataFile(
      meta: const DataFileMeta(
        assetPath: 'assets/data/equipment_templates.json',
        schemaVersion: 1,
        recordCount: 1,
        topLevelKeys: ['schemaVersion', 'equipment_templates'],
      ),
      json: {
        'schemaVersion': 1,
        'equipment_templates': [
          {
            'id': 'rusted_blade',
            'name': 'Rusted Blade',
            'slot': 'main_weapon',
            'allowedClasses': ['exile'],
            'minLevel': 1,
            'qualityPool': ['normal', 'magic', 'rare'],
            'baseStats': [
              {'stat': 'attack', 'min': 8, 'max': 14},
            ],
            'affixRules': {
              'prefixMin': 0,
              'prefixMax': 1,
              'suffixMin': 0,
              'suffixMax': 1,
              'allowedTags': ['poison', 'shadow'],
            },
          },
        ],
      },
    ),
    LoadedDataFile(
      meta: const DataFileMeta(
        assetPath: 'assets/data/quality_config.json',
        schemaVersion: 1,
        recordCount: 8,
        topLevelKeys: ['schemaVersion', 'qualities'],
      ),
      json: {
        'schemaVersion': 1,
        'qualities': [
          _quality('normal', 0, 0, 1, 0),
          _quality('magic', 1, 2, 1.08, 0),
          _quality('rare', 3, 4, 1.18, 0.02),
          _quality('epic', 4, 5, 1.32, 0.05),
          _quality('legendary', 5, 6, 1.5, 0.15),
          _quality('mythic', 6, 7, 1.75, 0.3),
          _quality('abyss', 7, 8, 2.05, 0.45),
          _quality('forbidden', 8, 8, 2.4, 0.65),
        ],
      },
    ),
  ]);
}

Map<String, Object?> _quality(
  String id,
  int affixMin,
  int affixMax,
  num statMultiplier,
  num specialEffectChance,
) {
  return {
    'id': id,
    'name': id,
    'affixMin': affixMin,
    'affixMax': affixMax,
    'statMultiplier': statMultiplier,
    'specialEffectChance': specialEffectChance,
  };
}
