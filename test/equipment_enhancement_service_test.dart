import 'package:abyss_relic/models/affix_config.dart';
import 'package:abyss_relic/models/character_state.dart';
import 'package:abyss_relic/models/class_config.dart';
import 'package:abyss_relic/models/data_file_meta.dart';
import 'package:abyss_relic/models/enhancement_config.dart';
import 'package:abyss_relic/models/equipment_instance.dart';
import 'package:abyss_relic/models/equipment_loadout.dart';
import 'package:abyss_relic/models/equipment_template.dart';
import 'package:abyss_relic/models/inventory_state.dart';
import 'package:abyss_relic/models/loaded_data_file.dart';
import 'package:abyss_relic/models/stat_block.dart';
import 'package:abyss_relic/systems/config/game_database.dart';
import 'package:abyss_relic/systems/equipment/equipment_enhancement_service.dart';
import 'package:abyss_relic/systems/stats/character_final_stats_service.dart';
import 'package:abyss_relic/systems/stats/equipment_stat_modifier_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EquipmentInstance supports enhanceLevel JSON round trip', () {
    final restored = EquipmentInstance.fromJson(_equipment()
        .copyWith(
          enhanceLevel: 2,
        )
        .toJson());

    expect(restored.enhanceLevel, 2);
  });

  test('EquipmentInstance legacy JSON defaults enhanceLevel to 0', () {
    final json = _equipment().toJson()..remove('enhanceLevel');

    final restored = EquipmentInstance.fromJson(json);

    expect(restored.enhanceLevel, 0);
  });

  test('enhancement_config parses cost and max level', () {
    final config = EnhancementConfig.fromJson(_enhancementRecord());

    expect(config.maxLevel, 10);
    expect(config.costForNextLevel(0).dust, 1);
    expect(config.costForNextLevel(0).gold, 10);
    expect(config.multiplierForLevel(0), 1.0);
    expect(config.multiplierForLevel(1), 1.05);
  });

  test('enhancement_config.json can be loaded by GameDatabase', () {
    final record = _database().findRecord('enhancement_config', 'default');

    expect(record, isNotNull);
    expect(EnhancementConfig.fromJson(record!).maxLevel, 10);
  });

  test('equipment enhances from +0 to +1 and consumes materials', () {
    final result = const EquipmentEnhancementService().enhance(
      state: _inventory(dust: 3, gold: 20),
      instanceId: 'eq_weapon',
      database: _database(),
    );

    expect(result.accepted, isTrue);
    expect(result.previousLevel, 0);
    expect(result.newLevel, 1);
    expect(result.consumedGold, 10);
    expect(result.consumedMaterials.single.quantity, 1);
    expect(result.state.equipmentInstances['eq_weapon']!.enhanceLevel, 1);
    expect(_quantity(result.state, 'gold'), 10);
    expect(_quantity(result.state, 'salvage_dust'), 2);
  });

  test('insufficient materials fail without changing state', () {
    final state = _inventory(dust: 0, gold: 20);
    final result = const EquipmentEnhancementService().enhance(
      state: state,
      instanceId: 'eq_weapon',
      database: _database(),
    );

    expect(result.accepted, isFalse);
    expect(result.reason, EquipmentEnhancementReason.insufficientDust);
    expect(result.state.equipmentInstances['eq_weapon']!.enhanceLevel, 0);
    expect(_quantity(result.state, 'gold'), 20);
  });

  test('missing gold fails without changing state', () {
    final result = const EquipmentEnhancementService().enhance(
      state: _inventory(dust: 3, gold: 0),
      instanceId: 'eq_weapon',
      database: _database(),
    );

    expect(result.accepted, isFalse);
    expect(result.reason, EquipmentEnhancementReason.insufficientGold);
  });

  test('max level and missing equipment fail', () {
    final service = const EquipmentEnhancementService();
    final maxed = service.enhance(
      state: _inventory(dust: 99, gold: 999, enhanceLevel: 10),
      instanceId: 'eq_weapon',
      database: _database(),
    );
    final missing = service.enhance(
      state: _inventory(dust: 99, gold: 999),
      instanceId: 'missing',
      database: _database(),
    );

    expect(maxed.reason, EquipmentEnhancementReason.maxLevelReached);
    expect(missing.reason, EquipmentEnhancementReason.equipmentNotFound);
  });

  test('enhanced equipment contributes higher base stats', () {
    final modifiers =
        const EquipmentStatModifierService().modifiersForEquipment(
      equipment: _equipment(enhanceLevel: 1),
      database: _database(),
    );

    expect(modifiers.modifiers.single.value, 10.5);
  });

  test('enhanced equipment increases final attack', () {
    const service = CharacterFinalStatsService();
    final base = service.compute(
      character: _character(),
      loadout: _loadout(),
      inventory: _inventory(dust: 0, gold: 0),
      database: _database(),
    );
    final enhanced = service.compute(
      character: _character(),
      loadout: _loadout(),
      inventory: _inventory(dust: 0, gold: 0, enhanceLevel: 1),
      database: _database(),
    );

    expect(enhanced.computedStats.finalStats.attack,
        greaterThan(base.computedStats.finalStats.attack));
  });
}

InventoryState _inventory({
  required int dust,
  required int gold,
  int enhanceLevel = 0,
}) {
  final equipment = _equipment(enhanceLevel: enhanceLevel);
  return InventoryState(
    equipmentInstanceIds: const ['eq_weapon'],
    equipmentInstances: {'eq_weapon': equipment},
    equipmentLoadout: _loadout(),
    materials: [
      MaterialStack(materialId: 'gold', quantity: gold),
      MaterialStack(materialId: 'salvage_dust', quantity: dust),
    ],
  );
}

EquipmentInstance _equipment({int enhanceLevel = 0}) {
  return EquipmentInstance(
    instanceId: 'eq_weapon',
    templateId: 'rusted_blade',
    qualityId: 'rare',
    level: 1,
    createdAt: DateTime.utc(2026, 6, 24),
    rolledBaseStats: const [
      RolledBaseStat(stat: 'attack', value: 10),
    ],
    rolledAffixes: const <RolledAffix>[],
    enhanceLevel: enhanceLevel,
  );
}

EquipmentLoadout _loadout() {
  return EquipmentLoadout.empty().equip(
    EquipmentSlot.mainWeapon,
    'eq_weapon',
  );
}

CharacterState _character() {
  return CharacterState(
    classConfig: const ClassConfig(
      id: 'exile',
      name: 'Exile',
      tags: ['poison'],
      baseStats: StatBlock(hp: 100, attack: 18, armor: 6),
      growth: StatBlock(hp: 10, attack: 2, armor: 1),
    ),
    level: 1,
    experience: 0,
  );
}

int _quantity(InventoryState state, String materialId) {
  return state.materials
      .where((material) => material.materialId == materialId)
      .fold<int>(0, (sum, material) => sum + material.quantity);
}

GameDatabase _database() {
  return GameDatabase.fromFiles([
    _file('assets/data/enhancement_config.json', {
      'schemaVersion': 1,
      'enhancement_config': [_enhancementRecord()],
    }),
    _file('assets/data/affixes.json', {
      'schemaVersion': 1,
      'affixes': <Object?>[],
    }),
  ]);
}

Map<String, Object?> _enhancementRecord() {
  return {
    'id': 'default',
    'name': 'Default Enhancement',
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
  };
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
