import 'package:abyss_relic/models/data_file_meta.dart';
import 'package:abyss_relic/models/loaded_data_file.dart';
import 'package:abyss_relic/models/loot_drop.dart';
import 'package:abyss_relic/systems/config/game_database.dart';
import 'package:abyss_relic/systems/drop/equipment_loot_materialization_service.dart';
import 'package:abyss_relic/systems/equipment/affix_roll_service.dart';
import 'package:abyss_relic/systems/equipment/equipment_generation_service.dart';
import 'package:abyss_relic/systems/equipment/equipment_template_service.dart';
import 'package:abyss_relic/systems/equipment/quality_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'EquipmentLootMaterializationService generates equipment from template drops',
      () {
    final service = _service();

    final result = service.materialize(
      drops: const [
        LootDrop.equipment(instanceId: 'rusted_blade', quantity: 2),
      ],
      classId: 'exile',
      level: 5,
      qualityId: 'rare',
      seed: 42,
    );

    expect(result.generatedEquipment, hasLength(2));
    expect(result.generatedEquipment.map((item) => item.templateId),
        everyElement('rusted_blade'));
    expect(result.inventoryDrops.map((drop) => drop.refId),
        result.generatedEquipment.map((item) => item.instanceId));
    expect(result.passthroughDrops, isEmpty);
  });

  test(
      'EquipmentLootMaterializationService keeps non-equipment drops unchanged',
      () {
    final service = _service();

    final result = service.materialize(
      drops: const [
        LootDrop.material(materialId: 'iron', quantity: 3),
      ],
      classId: 'exile',
      level: 5,
      qualityId: 'rare',
      seed: 42,
    );

    expect(result.generatedEquipment, isEmpty);
    expect(result.inventoryDrops.single.refId, 'iron');
    expect(result.passthroughDrops.single.refId, 'iron');
  });
}

EquipmentLootMaterializationService _service() {
  final database = _database();
  return EquipmentLootMaterializationService(
    generationService: EquipmentGenerationService(
      templateService: EquipmentTemplateService(database),
      qualityService: QualityService(database),
      affixRollService: AffixRollService(database),
    ),
  );
}

GameDatabase _database() {
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
              'allowedTags': ['poison'],
            },
          },
        ],
      },
    ),
    LoadedDataFile(
      meta: const DataFileMeta(
        assetPath: 'assets/data/quality_config.json',
        schemaVersion: 1,
        recordCount: 1,
        topLevelKeys: ['schemaVersion', 'qualities'],
      ),
      json: {
        'schemaVersion': 1,
        'qualities': [
          {
            'id': 'rare',
            'name': 'Rare',
            'affixMin': 1,
            'affixMax': 1,
            'statMultiplier': 1.18,
            'specialEffectChance': 0.02,
          },
        ],
      },
    ),
    LoadedDataFile(
      meta: const DataFileMeta(
        assetPath: 'assets/data/affixes.json',
        schemaVersion: 1,
        recordCount: 1,
        topLevelKeys: ['schemaVersion', 'affixes'],
      ),
      json: {
        'schemaVersion': 1,
        'affixes': [
          {
            'id': 'aff_poison_damage',
            'name': 'Poison Damage',
            'type': 'element',
            'tags': ['poison'],
            'minLevel': 1,
            'weight': 120,
            'rollRange': {'min': 0.06, 'max': 0.18, 'step': 0.01},
            'statModifiers': [
              {
                'stat': 'poison_damage',
                'mode': 'percent',
                'valueFromRoll': true,
              },
            ],
          },
        ],
      },
    ),
  ]);
}
