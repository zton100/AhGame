import '../../models/equipment_instance.dart';
import '../../models/inventory_state.dart';
import 'inventory_service.dart';

class EquipmentInstanceStore {
  const EquipmentInstanceStore();

  InventoryChangeResult addInstance({
    required InventoryState state,
    required EquipmentInstance instance,
  }) {
    final hasId = state.equipmentInstanceIds.contains(instance.instanceId);
    final hasInstance = state.equipmentInstances.containsKey(
      instance.instanceId,
    );

    if (hasId && hasInstance) {
      return InventoryChangeResult(
        accepted: true,
        state: state,
        reason: InventoryChangeReason.unchanged,
      );
    }

    if (!hasId && state.isEquipmentFull) {
      return InventoryChangeResult(
        accepted: false,
        state: state,
        reason: InventoryChangeReason.equipmentFull,
      );
    }

    return InventoryChangeResult(
      accepted: true,
      state: state.copyWith(
        equipmentInstanceIds: hasId
            ? state.equipmentInstanceIds
            : [
                ...state.equipmentInstanceIds,
                instance.instanceId,
              ],
        equipmentInstances: hasInstance
            ? state.equipmentInstances
            : {
                ...state.equipmentInstances,
                instance.instanceId: instance,
              },
      ),
      reason: InventoryChangeReason.added,
    );
  }

  InventoryState removeInstance({
    required InventoryState state,
    required String instanceId,
  }) {
    final equipmentInstanceIds = [
      for (final id in state.equipmentInstanceIds)
        if (id != instanceId) id,
    ];
    final equipmentInstances =
        Map<String, EquipmentInstance>.from(state.equipmentInstances)
          ..remove(instanceId);
    final lockedEquipmentInstanceIds = [
      for (final id in state.lockedEquipmentInstanceIds)
        if (id != instanceId) id,
    ];

    return state.copyWith(
      equipmentInstanceIds: equipmentInstanceIds,
      equipmentInstances: equipmentInstances,
      lockedEquipmentInstanceIds: lockedEquipmentInstanceIds,
    );
  }

  EquipmentInstance? findInstance({
    required InventoryState state,
    required String instanceId,
  }) {
    return state.equipmentInstances[instanceId];
  }

  EquipmentInstance requireInstance({
    required InventoryState state,
    required String instanceId,
  }) {
    final instance = findInstance(state: state, instanceId: instanceId);
    if (instance == null) {
      throw StateError('Equipment instance not found: $instanceId');
    }

    return instance;
  }

  List<EquipmentInstance> listInstancesByInventoryOrder({
    required InventoryState state,
  }) {
    return [
      for (final instanceId in state.equipmentInstanceIds)
        if (state.equipmentInstances[instanceId] != null)
          state.equipmentInstances[instanceId]!,
    ];
  }

  bool containsInstance({
    required InventoryState state,
    required String instanceId,
  }) {
    return state.equipmentInstanceIds.contains(instanceId) ||
        state.equipmentInstances.containsKey(instanceId);
  }
}
