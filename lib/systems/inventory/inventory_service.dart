import '../../models/inventory_state.dart';

class InventoryService {
  const InventoryService();

  InventoryChangeResult addEquipment({
    required InventoryState state,
    required String equipmentInstanceId,
  }) {
    if (state.equipmentInstanceIds.contains(equipmentInstanceId)) {
      return InventoryChangeResult(
        accepted: true,
        state: state,
        reason: InventoryChangeReason.unchanged,
      );
    }

    if (state.isEquipmentFull) {
      return InventoryChangeResult(
        accepted: false,
        state: state,
        reason: InventoryChangeReason.equipmentFull,
      );
    }

    return InventoryChangeResult(
      accepted: true,
      state: state.copyWith(
        equipmentInstanceIds: [
          ...state.equipmentInstanceIds,
          equipmentInstanceId,
        ],
      ),
      reason: InventoryChangeReason.added,
    );
  }

  InventoryChangeResult addMaterial({
    required InventoryState state,
    required String materialId,
    required int quantity,
  }) {
    if (quantity <= 0) {
      return InventoryChangeResult(
        accepted: false,
        state: state,
        reason: InventoryChangeReason.invalidQuantity,
      );
    }

    final materials = [...state.materials];
    final index = materials.indexWhere(
      (material) => material.materialId == materialId,
    );
    if (index == -1) {
      materials.add(MaterialStack(materialId: materialId, quantity: quantity));
    } else {
      final current = materials[index];
      materials[index] = current.copyWith(
        quantity: current.quantity + quantity,
      );
    }

    return InventoryChangeResult(
      accepted: true,
      state: state.copyWith(materials: materials),
      reason: InventoryChangeReason.added,
    );
  }
}

class InventoryChangeResult {
  const InventoryChangeResult({
    required this.accepted,
    required this.state,
    required this.reason,
  });

  final bool accepted;
  final InventoryState state;
  final InventoryChangeReason reason;
}

enum InventoryChangeReason {
  added,
  unchanged,
  equipmentFull,
  invalidQuantity,
}
