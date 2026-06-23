import 'package:abyss_relic/models/equipment_instance.dart';
import 'package:abyss_relic/models/inventory_state.dart';
import 'package:abyss_relic/models/save_data.dart';
import 'package:abyss_relic/systems/inventory/equipment_instance_store.dart';
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
    final equipment = _equipment('eq_1');
    final state = InventoryState(
      equipmentInstanceIds: ['eq_1'],
      equipmentInstances: {'eq_1': equipment},
      equipmentCapacity: 20,
      materials: const [
        MaterialStack(materialId: 'iron', quantity: 5),
      ],
      lockedEquipmentInstanceIds: const ['eq_1'],
    );

    final restored = InventoryState.fromJson(state.toJson());

    expect(restored.equipmentInstanceIds, ['eq_1']);
    expect(restored.equipmentInstances['eq_1']!.templateId, 'rusted_blade');
    expect(restored.equipmentInstances['eq_1']!.qualityId, 'rare');
    expect(
      restored.equipmentInstances['eq_1']!.rolledBaseStats.single.value,
      12,
    );
    expect(restored.equipmentCapacity, 20);
    expect(restored.materials.single.materialId, 'iron');
    expect(restored.materials.single.quantity, 5);
    expect(restored.lockedEquipmentInstanceIds, ['eq_1']);
  });

  test('InventorySave preserves legacy saves and new inventory fields', () {
    final legacy = InventorySave.fromJson({
      'equipmentInstanceIds': ['eq_legacy'],
    });
    final equipment = _equipment('eq_1');
    final current = InventorySave(
      equipmentInstanceIds: ['eq_1'],
      equipmentInstances: {'eq_1': equipment},
      equipmentCapacity: 30,
      materials: const [MaterialStack(materialId: 'iron', quantity: 4)],
      lockedEquipmentInstanceIds: const ['eq_1'],
    );

    expect(legacy.equipmentInstanceIds, ['eq_legacy']);
    expect(legacy.equipmentInstances, isEmpty);
    expect(legacy.equipmentCapacity, InventoryState.defaultEquipmentCapacity);
    expect(legacy.materials, isEmpty);
    expect(legacy.lockedEquipmentInstanceIds, isEmpty);
    expect(
      (current.toJson()['equipmentInstances'] as Map<String, Object?>)['eq_1'],
      equipment.toJson(),
    );
    expect(current.toJson()['materials'], [
      {'materialId': 'iron', 'quantity': 4},
    ]);
    expect(current.toJson()['lockedEquipmentInstanceIds'], ['eq_1']);
  });

  test('EquipmentInstanceStore adds equipment id and full instance together',
      () {
    const store = EquipmentInstanceStore();
    final equipment = _equipment('eq_1');

    final result = store.addInstance(
      state: const InventoryState(equipmentInstanceIds: []),
      instance: equipment,
    );

    expect(result.accepted, isTrue);
    expect(result.state.equipmentInstanceIds, ['eq_1']);
    expect(result.state.equipmentInstances['eq_1'], equipment);
  });

  test('EquipmentInstanceStore does not leave orphan instances when full', () {
    const store = EquipmentInstanceStore();
    final result = store.addInstance(
      state: InventoryState(
        equipmentInstanceIds: const ['eq_1'],
        equipmentInstances: {'eq_1': _equipment('eq_1')},
        equipmentCapacity: 1,
      ),
      instance: _equipment('eq_2'),
    );

    expect(result.accepted, isFalse);
    expect(result.reason, InventoryChangeReason.equipmentFull);
    expect(result.state.equipmentInstanceIds, ['eq_1']);
    expect(result.state.equipmentInstances.keys, ['eq_1']);
  });

  test('EquipmentInstanceStore removes equipment id and full instance', () {
    const store = EquipmentInstanceStore();
    final state = InventoryState(
      equipmentInstanceIds: const ['eq_1', 'eq_2'],
      equipmentInstances: {
        'eq_1': _equipment('eq_1'),
        'eq_2': _equipment('eq_2'),
      },
      lockedEquipmentInstanceIds: const ['eq_1'],
    );

    final updated = store.removeInstance(state: state, instanceId: 'eq_1');

    expect(updated.equipmentInstanceIds, ['eq_2']);
    expect(updated.equipmentInstances.keys, ['eq_2']);
    expect(updated.lockedEquipmentInstanceIds, isEmpty);
  });

  test('EquipmentInstanceStore repairs id-only equipment ownership', () {
    const store = EquipmentInstanceStore();
    final equipment = _equipment('eq_1');

    final result = store.addInstance(
      state: const InventoryState(equipmentInstanceIds: ['eq_1']),
      instance: equipment,
    );

    expect(result.accepted, isTrue);
    expect(result.state.equipmentInstanceIds, ['eq_1']);
    expect(result.state.equipmentInstances['eq_1'], equipment);
  });

  test('EquipmentInstanceStore rejects orphan map entries when bag is full',
      () {
    const store = EquipmentInstanceStore();
    final result = store.addInstance(
      state: InventoryState(
        equipmentInstanceIds: const ['eq_1'],
        equipmentInstances: {'eq_2': _equipment('eq_2')},
        equipmentCapacity: 1,
      ),
      instance: _equipment('eq_2'),
    );

    expect(result.accepted, isFalse);
    expect(result.state.equipmentInstanceIds, ['eq_1']);
    expect(result.state.equipmentInstances.keys, ['eq_2']);
  });

  test('EquipmentInstanceStore lists instances by inventory order', () {
    const store = EquipmentInstanceStore();
    final state = InventoryState(
      equipmentInstanceIds: const ['eq_2', 'eq_1'],
      equipmentInstances: {
        'eq_1': _equipment('eq_1'),
        'eq_2': _equipment('eq_2'),
      },
    );

    final instances = store.listInstancesByInventoryOrder(state: state);

    expect(instances.map((instance) => instance.instanceId), ['eq_2', 'eq_1']);
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
