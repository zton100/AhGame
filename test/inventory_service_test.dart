import 'package:abyss_relic/models/equipment_instance.dart';
import 'package:abyss_relic/models/equipment_loadout.dart';
import 'package:abyss_relic/models/equipment_template.dart';
import 'package:abyss_relic/models/inventory_state.dart';
import 'package:abyss_relic/models/save_data.dart';
import 'package:abyss_relic/systems/inventory/equipment_inventory_action_service.dart';
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
      equipmentLoadout: EquipmentLoadout.empty().equip(
        EquipmentSlot.mainWeapon,
        'eq_1',
      ),
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
    expect(
      restored.equipmentLoadout.equippedInstanceId(EquipmentSlot.mainWeapon),
      'eq_1',
    );
  });

  test('InventorySave preserves legacy saves and new inventory fields', () {
    final legacy = InventorySave.fromJson({
      'equipmentInstanceIds': ['eq_legacy'],
    });
    final equipment = _equipment('eq_1');
    final current = InventorySave(
      equipmentInstanceIds: ['eq_1'],
      equipmentInstances: {'eq_1': equipment},
      equipmentLoadout: EquipmentLoadout.empty().equip(
        EquipmentSlot.mainWeapon,
        'eq_1',
      ),
      equipmentCapacity: 30,
      materials: const [MaterialStack(materialId: 'iron', quantity: 4)],
      lockedEquipmentInstanceIds: const ['eq_1'],
    );

    expect(legacy.equipmentInstanceIds, ['eq_legacy']);
    expect(legacy.equipmentInstances, isEmpty);
    expect(legacy.equipmentCapacity, InventoryState.defaultEquipmentCapacity);
    expect(legacy.materials, isEmpty);
    expect(legacy.lockedEquipmentInstanceIds, isEmpty);
    expect(legacy.equipmentLoadout.equippedBySlot, isEmpty);
    expect(
      (current.toJson()['equipmentInstances'] as Map<String, Object?>)['eq_1'],
      equipment.toJson(),
    );
    expect(current.toJson()['materials'], [
      {'materialId': 'iron', 'quantity': 4},
    ]);
    expect(current.toJson()['lockedEquipmentInstanceIds'], ['eq_1']);
    expect(current.toJson()['equipmentLoadout'], {
      'equippedBySlot': {'main_weapon': 'eq_1'},
    });
  });

  test('InventoryState locks and unlocks equipment ids', () {
    const state = InventoryState(equipmentInstanceIds: ['eq_1']);

    final locked = state.lockEquipment('eq_1');
    final stillLocked = locked.lockEquipment('eq_1');
    final unlocked = stillLocked.unlockEquipment('eq_1');

    expect(locked.isLocked('eq_1'), isTrue);
    expect(stillLocked.lockedEquipmentInstanceIds, ['eq_1']);
    expect(unlocked.isLocked('eq_1'), isFalse);
    expect(unlocked.lockedEquipmentInstanceIds, isEmpty);
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

  test('EquipmentInventoryActionService rejects locked equipment salvage', () {
    const service = EquipmentInventoryActionService();
    final state = InventoryState(
      equipmentInstanceIds: const ['eq_1'],
      equipmentInstances: {'eq_1': _equipment('eq_1')},
      lockedEquipmentInstanceIds: const ['eq_1'],
    );

    final result = service.salvage(
      state: state,
      loadout: const EquipmentLoadout.empty(),
      instanceId: 'eq_1',
    );

    expect(result.accepted, isFalse);
    expect(result.reason, EquipmentInventoryActionReason.locked);
    expect(result.state.equipmentInstances.keys, ['eq_1']);
  });

  test('EquipmentInventoryActionService rejects equipped equipment salvage',
      () {
    const service = EquipmentInventoryActionService();
    final state = InventoryState(
      equipmentInstanceIds: const ['eq_1'],
      equipmentInstances: {'eq_1': _equipment('eq_1')},
    );

    final result = service.salvage(
      state: state,
      loadout: EquipmentLoadout.empty().equip(
        EquipmentSlot.mainWeapon,
        'eq_1',
      ),
      instanceId: 'eq_1',
    );

    expect(result.accepted, isFalse);
    expect(result.reason, EquipmentInventoryActionReason.equipped);
    expect(result.state.equipmentInstances.keys, ['eq_1']);
  });

  test('EquipmentInventoryActionService salvages equipment into material', () {
    const service = EquipmentInventoryActionService();
    final state = InventoryState(
      equipmentInstanceIds: const ['eq_1'],
      equipmentInstances: {'eq_1': _equipment('eq_1')},
    );

    final result = service.salvage(
      state: state,
      loadout: const EquipmentLoadout.empty(),
      instanceId: 'eq_1',
    );

    expect(result.accepted, isTrue);
    expect(result.state.equipmentInstanceIds, isEmpty);
    expect(result.state.equipmentInstances, isEmpty);
    expect(result.gainedMaterials.single.materialId, 'salvage_dust');
    expect(result.gainedMaterials.single.quantity, 1);
    expect(result.state.materials.single.materialId, 'salvage_dust');
    expect(result.state.materials.single.quantity, 1);
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
