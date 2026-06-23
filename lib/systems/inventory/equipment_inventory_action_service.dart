import '../../models/equipment_loadout.dart';
import '../../models/inventory_state.dart';
import 'equipment_instance_store.dart';
import 'inventory_service.dart';

class EquipmentInventoryActionService {
  const EquipmentInventoryActionService({
    EquipmentInstanceStore equipmentStore = const EquipmentInstanceStore(),
    InventoryService inventoryService = const InventoryService(),
  })  : _equipmentStore = equipmentStore,
        _inventoryService = inventoryService;

  static const salvageDustMaterialId = 'salvage_dust';

  final EquipmentInstanceStore _equipmentStore;
  final InventoryService _inventoryService;

  EquipmentSalvageResult salvage({
    required InventoryState state,
    required EquipmentLoadout loadout,
    required String instanceId,
  }) {
    if (!_equipmentStore.containsInstance(
      state: state,
      instanceId: instanceId,
    )) {
      return EquipmentSalvageResult(
        accepted: false,
        state: state,
        gainedMaterials: const [],
        reason: EquipmentInventoryActionReason.notFound,
      );
    }

    if (state.isLocked(instanceId)) {
      return EquipmentSalvageResult(
        accepted: false,
        state: state,
        gainedMaterials: const [],
        reason: EquipmentInventoryActionReason.locked,
      );
    }

    if (loadout.equippedBySlot.containsValue(instanceId)) {
      return EquipmentSalvageResult(
        accepted: false,
        state: state,
        gainedMaterials: const [],
        reason: EquipmentInventoryActionReason.equipped,
      );
    }

    final gainedMaterials = const [
      MaterialStack(materialId: salvageDustMaterialId, quantity: 1),
    ];
    var next = _equipmentStore.removeInstance(
      state: state,
      instanceId: instanceId,
    );
    for (final material in gainedMaterials) {
      final result = _inventoryService.addMaterial(
        state: next,
        materialId: material.materialId,
        quantity: material.quantity,
      );
      next = result.state;
    }

    return EquipmentSalvageResult(
      accepted: true,
      state: next,
      gainedMaterials: gainedMaterials,
      reason: EquipmentInventoryActionReason.salvaged,
    );
  }
}

class EquipmentSalvageResult {
  const EquipmentSalvageResult({
    required this.accepted,
    required this.state,
    required this.gainedMaterials,
    required this.reason,
  });

  final bool accepted;
  final InventoryState state;
  final List<MaterialStack> gainedMaterials;
  final EquipmentInventoryActionReason reason;
}

enum EquipmentInventoryActionReason {
  salvaged,
  locked,
  equipped,
  notFound,
}
