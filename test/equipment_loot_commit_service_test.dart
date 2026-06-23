import 'package:abyss_relic/models/equipment_instance.dart';
import 'package:abyss_relic/models/inventory_state.dart';
import 'package:abyss_relic/models/loot_drop.dart';
import 'package:abyss_relic/systems/drop/equipment_loot_materialization_service.dart';
import 'package:abyss_relic/systems/inventory/equipment_loot_commit_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EquipmentLootCommitService stores generated equipment instances', () {
    const service = EquipmentLootCommitService();
    final equipment = _equipment('eq_1');

    final result = service.commitMaterialized(
      state: const InventoryState(equipmentInstanceIds: []),
      materialized: EquipmentLootMaterializationResult(
        generatedEquipment: [equipment],
        inventoryDrops: const [LootDrop.equipment(instanceId: 'eq_1')],
        passthroughDrops: const [
          LootDrop.material(materialId: 'iron', quantity: 1)
        ],
      ),
    );

    expect(result.state.equipmentInstanceIds, ['eq_1']);
    expect(result.state.equipmentInstances['eq_1'], equipment);
    expect(result.state.materials.single.materialId, 'iron');
    expect(result.acceptedEquipment, [equipment]);
    expect(result.rejectedEquipment, isEmpty);
  });

  test('EquipmentLootCommitService does not save orphan instance when full',
      () {
    const service = EquipmentLootCommitService();
    final existing = _equipment('eq_1');
    final rejected = _equipment('eq_2');

    final result = service.commitMaterialized(
      state: InventoryState(
        equipmentInstanceIds: const ['eq_1'],
        equipmentInstances: {'eq_1': existing},
        equipmentCapacity: 1,
      ),
      materialized: EquipmentLootMaterializationResult(
        generatedEquipment: [rejected],
        inventoryDrops: const [LootDrop.equipment(instanceId: 'eq_2')],
        passthroughDrops: const [],
      ),
    );

    expect(result.state.equipmentInstanceIds, ['eq_1']);
    expect(result.state.equipmentInstances.keys, ['eq_1']);
    expect(result.acceptedEquipment, isEmpty);
    expect(result.rejectedEquipment, [rejected]);
  });

  test('EquipmentLootCommitService skips duplicate equipment instances', () {
    const service = EquipmentLootCommitService();
    final equipment = _equipment('eq_1');

    final result = service.commitMaterialized(
      state: InventoryState(
        equipmentInstanceIds: const ['eq_1'],
        equipmentInstances: {'eq_1': equipment},
      ),
      materialized: EquipmentLootMaterializationResult(
        generatedEquipment: [equipment],
        inventoryDrops: const [LootDrop.equipment(instanceId: 'eq_1')],
        passthroughDrops: const [],
      ),
    );

    expect(result.state.equipmentInstanceIds, ['eq_1']);
    expect(result.state.equipmentInstances, {'eq_1': equipment});
    expect(result.acceptedEquipment, [equipment]);
  });
}

EquipmentInstance _equipment(String instanceId) {
  return EquipmentInstance(
    instanceId: instanceId,
    templateId: 'rusted_blade',
    qualityId: 'rare',
    level: 5,
    createdAt: DateTime.utc(2026, 6, 24),
    rolledBaseStats: const [RolledBaseStat(stat: 'attack', value: 12)],
    rolledAffixes: const [],
  );
}
