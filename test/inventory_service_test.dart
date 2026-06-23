import 'package:abyss_relic/models/inventory_state.dart';
import 'package:abyss_relic/models/save_data.dart';
import 'package:abyss_relic/systems/inventory/inventory_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('InventoryService adds equipment until capacity is reached', () {
    const service = InventoryService();
    final first = service.addEquipment(
      state:
          const InventoryState(equipmentInstanceIds: [], equipmentCapacity: 1),
      equipmentInstanceId: 'eq_1',
    );
    final second = service.addEquipment(
      state: first.state,
      equipmentInstanceId: 'eq_2',
    );

    expect(first.accepted, isTrue);
    expect(first.state.equipmentInstanceIds, ['eq_1']);
    expect(second.accepted, isFalse);
    expect(second.reason, InventoryChangeReason.equipmentFull);
    expect(second.state.equipmentInstanceIds, ['eq_1']);
  });

  test('InventoryService stacks materials by id without equipment capacity',
      () {
    const service = InventoryService();
    final state = service
        .addMaterial(
          state: const InventoryState(
            equipmentInstanceIds: [],
            equipmentCapacity: 0,
          ),
          materialId: 'iron',
          quantity: 3,
        )
        .state;
    final stacked = service.addMaterial(
      state: state,
      materialId: 'iron',
      quantity: 2,
    );

    expect(stacked.accepted, isTrue);
    expect(stacked.state.materials.single.materialId, 'iron');
    expect(stacked.state.materials.single.quantity, 5);
    expect(stacked.state.equipmentInstanceIds, isEmpty);
  });

  test('InventoryState supports JSON round trip', () {
    const state = InventoryState(
      equipmentInstanceIds: ['eq_1'],
      equipmentCapacity: 20,
      materials: [
        MaterialStack(materialId: 'iron', quantity: 5),
      ],
    );

    final restored = InventoryState.fromJson(state.toJson());

    expect(restored.equipmentInstanceIds, ['eq_1']);
    expect(restored.equipmentCapacity, 20);
    expect(restored.materials.single.materialId, 'iron');
    expect(restored.materials.single.quantity, 5);
  });

  test('InventorySave preserves legacy saves and new inventory fields', () {
    final legacy = InventorySave.fromJson({
      'equipmentInstanceIds': ['eq_legacy'],
    });
    const current = InventorySave(
      equipmentInstanceIds: ['eq_1'],
      equipmentCapacity: 30,
      materials: [MaterialStack(materialId: 'iron', quantity: 4)],
    );

    expect(legacy.equipmentInstanceIds, ['eq_legacy']);
    expect(legacy.equipmentCapacity, InventoryState.defaultEquipmentCapacity);
    expect(legacy.materials, isEmpty);
    expect(current.toJson()['materials'], [
      {'materialId': 'iron', 'quantity': 4},
    ]);
  });
}
