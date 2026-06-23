import 'package:abyss_relic/models/inventory_state.dart';
import 'package:abyss_relic/models/loot_drop.dart';
import 'package:abyss_relic/systems/inventory/loot_inventory_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('LootInventoryService adds equipment and stacked materials', () {
    const service = LootInventoryService();
    final result = service.applyDrops(
      state: const InventoryState(equipmentInstanceIds: []),
      drops: const [
        LootDrop.equipment(instanceId: 'eq_1'),
        LootDrop.material(materialId: 'iron', quantity: 2),
        LootDrop.material(materialId: 'iron', quantity: 3),
      ],
    );

    expect(result.state.equipmentInstanceIds, ['eq_1']);
    expect(result.state.materials.single.materialId, 'iron');
    expect(result.state.materials.single.quantity, 5);
    expect(result.acceptedDrops, hasLength(3));
    expect(result.rejectedDrops, isEmpty);
  });

  test('LootInventoryService rejects equipment when inventory is full', () {
    const service = LootInventoryService();
    final result = service.applyDrops(
      state: const InventoryState(
        equipmentInstanceIds: ['eq_1'],
        equipmentCapacity: 1,
      ),
      drops: const [
        LootDrop.equipment(instanceId: 'eq_2'),
        LootDrop.material(materialId: 'iron', quantity: 1),
      ],
    );

    expect(result.state.equipmentInstanceIds, ['eq_1']);
    expect(result.state.materials.single.quantity, 1);
    expect(result.acceptedDrops.single.drop.type, LootDropType.material);
    expect(result.rejectedDrops.single.reason, LootInventoryDropReason.full);
  });

  test('LootInventoryService ignores unsupported drop types safely', () {
    const service = LootInventoryService();
    final result = service.applyDrops(
      state: const InventoryState(equipmentInstanceIds: []),
      drops: const [
        LootDrop.other(
            type: 'soul_core', refId: 'core_plague_heart', quantity: 1),
      ],
    );

    expect(result.state.equipmentInstanceIds, isEmpty);
    expect(result.acceptedDrops, isEmpty);
    expect(result.rejectedDrops.single.reason,
        LootInventoryDropReason.unsupportedType);
  });
}
