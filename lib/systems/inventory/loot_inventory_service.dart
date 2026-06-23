import '../../models/inventory_state.dart';
import '../../models/loot_drop.dart';
import 'inventory_service.dart';

class LootInventoryService {
  const LootInventoryService({
    InventoryService inventoryService = const InventoryService(),
  }) : _inventoryService = inventoryService;

  final InventoryService _inventoryService;

  LootInventoryResult applyDrops({
    required InventoryState state,
    required Iterable<LootDrop> drops,
  }) {
    var current = state;
    final accepted = <LootInventoryDropResult>[];
    final rejected = <LootInventoryDropResult>[];

    for (final drop in drops) {
      switch (drop.type) {
        case LootDropType.equipment:
          final result = _inventoryService.addEquipment(
            state: current,
            equipmentInstanceId: drop.refId,
          );
          if (result.accepted) {
            current = result.state;
            accepted.add(LootInventoryDropResult.accepted(drop));
          } else {
            rejected.add(LootInventoryDropResult.rejected(
              drop: drop,
              reason: LootInventoryDropReason.full,
            ));
          }
          break;
        case LootDropType.material:
          final result = _inventoryService.addMaterial(
            state: current,
            materialId: drop.refId,
            quantity: drop.quantity,
          );
          if (result.accepted) {
            current = result.state;
            accepted.add(LootInventoryDropResult.accepted(drop));
          } else {
            rejected.add(LootInventoryDropResult.rejected(
              drop: drop,
              reason: LootInventoryDropReason.invalidQuantity,
            ));
          }
          break;
        case LootDropType.other:
          rejected.add(LootInventoryDropResult.rejected(
            drop: drop,
            reason: LootInventoryDropReason.unsupportedType,
          ));
          break;
      }
    }

    return LootInventoryResult(
      state: current,
      acceptedDrops: List.unmodifiable(accepted),
      rejectedDrops: List.unmodifiable(rejected),
    );
  }
}

class LootInventoryResult {
  const LootInventoryResult({
    required this.state,
    required this.acceptedDrops,
    required this.rejectedDrops,
  });

  final InventoryState state;
  final List<LootInventoryDropResult> acceptedDrops;
  final List<LootInventoryDropResult> rejectedDrops;
}

class LootInventoryDropResult {
  const LootInventoryDropResult._({
    required this.drop,
    required this.accepted,
    required this.reason,
  });

  const LootInventoryDropResult.accepted(LootDrop drop)
      : this._(
          drop: drop,
          accepted: true,
          reason: LootInventoryDropReason.accepted,
        );

  const LootInventoryDropResult.rejected({
    required LootDrop drop,
    required LootInventoryDropReason reason,
  }) : this._(
          drop: drop,
          accepted: false,
          reason: reason,
        );

  final LootDrop drop;
  final bool accepted;
  final LootInventoryDropReason reason;
}

enum LootInventoryDropReason {
  accepted,
  full,
  invalidQuantity,
  unsupportedType,
}
