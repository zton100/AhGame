import 'package:abyss_relic/models/data_file_meta.dart';
import 'package:abyss_relic/models/equipment_instance.dart';
import 'package:abyss_relic/models/equipment_loadout.dart';
import 'package:abyss_relic/models/equipment_template.dart';
import 'package:abyss_relic/models/inventory_state.dart';
import 'package:abyss_relic/models/loaded_data_file.dart';
import 'package:abyss_relic/systems/config/game_database.dart';
import 'package:abyss_relic/systems/equipment/auto_enhancement_service.dart';
import 'package:abyss_relic/systems/equipment/equipment_enhancement_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recommends equipped main weapon first', () {
    final recommendation = const AutoEnhancementService().recommend(
      inventory: _inventory(dust: 5, gold: 50),
      database: _database(),
    );

    expect(recommendation.accepted, isTrue);
    expect(recommendation.instanceId, 'weapon');
    expect(recommendation.preview?.newLevel, 1);
  });

  test('enhanceRecommended upgrades the recommended equipment', () {
    final result = const AutoEnhancementService().enhanceRecommended(
      inventory: _inventory(dust: 5, gold: 50),
      database: _database(),
    );

    expect(result.accepted, isTrue);
    expect(result.instanceId, 'weapon');
    expect(result.state.equipmentInstances['weapon']!.enhanceLevel, 1);
  });

  test('returns insufficient materials when equipped gear cannot be enhanced',
      () {
    final result = const AutoEnhancementService().enhanceRecommended(
      inventory: _inventory(dust: 0, gold: 50),
      database: _database(),
    );

    expect(result.accepted, isFalse);
    expect(result.reason, EquipmentEnhancementReason.insufficientDust);
  });

  test('returns missing equipment when nothing is equipped', () {
    final result = const AutoEnhancementService().enhanceRecommended(
      inventory: _inventory(dust: 5, gold: 50, equipped: false),
      database: _database(),
    );

    expect(result.accepted, isFalse);
    expect(result.reason, EquipmentEnhancementReason.equipmentNotFound);
  });
}

InventoryState _inventory({
  required int dust,
  required int gold,
  bool equipped = true,
}) {
  return InventoryState(
    equipmentInstanceIds: const ['weapon', 'helm'],
    equipmentInstances: {
      'weapon': _equipment('weapon', 'rusted_blade', enhanceLevel: 0),
      'helm': _equipment('helm', 'grave_helm', enhanceLevel: 0),
    },
    equipmentLoadout: equipped
        ? EquipmentLoadout.empty()
            .equip(EquipmentSlot.mainWeapon, 'weapon')
            .equip(EquipmentSlot.helmet, 'helm')
        : const EquipmentLoadout.empty(),
    materials: [
      MaterialStack(materialId: 'gold', quantity: gold),
      MaterialStack(materialId: 'salvage_dust', quantity: dust),
    ],
  );
}

EquipmentInstance _equipment(
  String id,
  String templateId, {
  required int enhanceLevel,
}) {
  return EquipmentInstance(
    instanceId: id,
    templateId: templateId,
    qualityId: 'rare',
    level: 1,
    createdAt: DateTime.utc(2026, 6, 24),
    rolledBaseStats: const [
      RolledBaseStat(stat: 'attack', value: 10),
    ],
    rolledAffixes: const [],
    enhanceLevel: enhanceLevel,
  );
}

GameDatabase _database() {
  return GameDatabase.fromFiles([
    _file('assets/data/enhancement_config.json', {
      'schemaVersion': 1,
      'enhancement_config': [
        {
          'id': 'default',
          'name': 'Default',
          'maxLevel': 10,
          'dustCostByLevel': [1, 2, 3, 5, 8, 12, 18, 25, 35, 50],
          'goldCostByLevel': [10, 20, 35, 55, 80, 120, 180, 260, 360, 500],
          'statMultiplierByLevel': [
            1.05,
            1.10,
            1.16,
            1.22,
            1.30,
            1.38,
            1.47,
            1.57,
            1.68,
            1.80,
          ],
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
