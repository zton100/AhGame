import 'package:abyss_relic/models/data_file_meta.dart';
import 'package:abyss_relic/models/equipment_instance.dart';
import 'package:abyss_relic/models/loaded_data_file.dart';
import 'package:abyss_relic/systems/config/game_database.dart';
import 'package:abyss_relic/systems/equipment/equipment_generation_service.dart';
import 'package:abyss_relic/systems/equipment/equipment_template_service.dart';
import 'package:abyss_relic/systems/equipment/quality_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EquipmentGenerationService creates deterministic equipment by seed',
      () {
    final service = _generationService();

    final first = service.generate(
      templateId: 'rusted_blade',
      qualityId: 'rare',
      classId: 'exile',
      level: 5,
      seed: 42,
    );
    final second = service.generate(
      templateId: 'rusted_blade',
      qualityId: 'rare',
      classId: 'exile',
      level: 5,
      seed: 42,
    );

    expect(first.instanceId, second.instanceId);
    expect(first.rolledBaseStats.single.value,
        second.rolledBaseStats.single.value);
  });

  test('EquipmentGenerationService creates unique ids for different seeds', () {
    final service = _generationService();

    final first = service.generate(
      templateId: 'rusted_blade',
      qualityId: 'rare',
      classId: 'exile',
      level: 5,
      seed: 1,
    );
    final second = service.generate(
      templateId: 'rusted_blade',
      qualityId: 'rare',
      classId: 'exile',
      level: 5,
      seed: 2,
    );

    expect(first.instanceId, isNot(second.instanceId));
  });

  test('EquipmentGenerationService rolls base stats inside quality range', () {
    final service = _generationService();

    final equipment = service.generate(
      templateId: 'rusted_blade',
      qualityId: 'rare',
      classId: 'exile',
      level: 5,
      seed: 7,
    );
    final attack = equipment.rolledBaseStats.single;

    expect(attack.stat, 'attack');
    expect(attack.value, greaterThanOrEqualTo(8 * 1.18));
    expect(attack.value, lessThanOrEqualTo(14 * 1.18));
  });

  test('EquipmentInstance supports JSON round trip', () {
    final equipment = _generationService().generate(
      templateId: 'rusted_blade',
      qualityId: 'rare',
      classId: 'exile',
      level: 5,
      seed: 42,
    );

    final restored = EquipmentInstance.fromJson(equipment.toJson());

    expect(restored.instanceId, equipment.instanceId);
    expect(restored.templateId, 'rusted_blade');
    expect(restored.qualityId, 'rare');
    expect(restored.rolledBaseStats.single.value,
        equipment.rolledBaseStats.single.value);
  });

  test('EquipmentGenerationService rejects class and level mismatches', () {
    final service = _generationService();

    expect(
      () => service.generate(
        templateId: 'rusted_blade',
        qualityId: 'rare',
        classId: 'ember_mage',
        level: 5,
        seed: 42,
      ),
      throwsA(isA<StateError>()),
    );
    expect(
      () => service.generate(
        templateId: 'rusted_blade',
        qualityId: 'rare',
        classId: 'exile',
        level: 0,
        seed: 42,
      ),
      throwsA(isA<StateError>()),
    );
  });
}

EquipmentGenerationService _generationService() {
  final database = GameDatabase.fromFiles([
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
        recordCount: 1,
        topLevelKeys: ['schemaVersion', 'qualities'],
      ),
      json: {
        'schemaVersion': 1,
        'qualities': [
          {
            'id': 'rare',
            'name': 'Rare',
            'affixMin': 3,
            'affixMax': 4,
            'statMultiplier': 1.18,
            'specialEffectChance': 0.02,
          },
        ],
      },
    ),
  ]);

  return EquipmentGenerationService(
    templateService: EquipmentTemplateService(database),
    qualityService: QualityService(database),
  );
}
