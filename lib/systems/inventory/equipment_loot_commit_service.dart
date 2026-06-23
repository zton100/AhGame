import '../../models/equipment_instance.dart';
import '../../models/inventory_state.dart';
import '../../systems/drop/equipment_loot_materialization_service.dart';
import 'equipment_instance_store.dart';
import 'inventory_service.dart';
import 'loot_inventory_service.dart';

class EquipmentLootCommitService {
  const EquipmentLootCommitService({
    EquipmentInstanceStore equipmentStore = const EquipmentInstanceStore(),
    LootInventoryService lootInventoryService = const LootInventoryService(),
  })  : _equipmentStore = equipmentStore,
        _lootInventoryService = lootInventoryService;

  final EquipmentInstanceStore _equipmentStore;
  final LootInventoryService _lootInventoryService;

  EquipmentLootCommitResult commitMaterialized({
    required InventoryState state,
    required EquipmentLootMaterializationResult materialized,
  }) {
    var current = state;
    final acceptedEquipment = <EquipmentInstance>[];
    final rejectedEquipment = <EquipmentInstance>[];

    for (final instance in materialized.generatedEquipment) {
      final result = _equipmentStore.addInstance(
        state: current,
        instance: instance,
      );
      if (result.accepted) {
        current = result.state;
        acceptedEquipment.add(instance);
      } else if (result.reason == InventoryChangeReason.equipmentFull) {
        rejectedEquipment.add(instance);
      }
    }

    final passthroughResult = _lootInventoryService.applyDrops(
      state: current,
      drops: materialized.passthroughDrops,
    );

    return EquipmentLootCommitResult(
      state: passthroughResult.state,
      acceptedEquipment: List.unmodifiable(acceptedEquipment),
      rejectedEquipment: List.unmodifiable(rejectedEquipment),
      passthroughResult: passthroughResult,
    );
  }
}

class EquipmentLootCommitResult {
  const EquipmentLootCommitResult({
    required this.state,
    required this.acceptedEquipment,
    required this.rejectedEquipment,
    required this.passthroughResult,
  });

  final InventoryState state;
  final List<EquipmentInstance> acceptedEquipment;
  final List<EquipmentInstance> rejectedEquipment;
  final LootInventoryResult passthroughResult;
}
