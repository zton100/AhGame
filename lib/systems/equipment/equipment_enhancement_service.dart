import '../../models/enhancement_config.dart';
import '../../models/inventory_state.dart';
import '../battle/battle_settlement_service.dart';
import '../config/game_database.dart';
import '../inventory/equipment_inventory_action_service.dart';

class EquipmentEnhancementService {
  const EquipmentEnhancementService();

  EnhancementConfig requireConfig(GameDatabase database) {
    final record = database.findRecord('enhancement_config', 'default');
    if (record == null) {
      throw StateError('Enhancement config not found: default');
    }

    return EnhancementConfig.fromJson(record);
  }

  bool canEnhance({
    required InventoryState state,
    required String instanceId,
    required GameDatabase database,
  }) {
    return enhance(
      state: state,
      instanceId: instanceId,
      database: database,
      dryRun: true,
    ).accepted;
  }

  EnhancementCost costForNextLevel({
    required int currentLevel,
    required GameDatabase database,
  }) {
    return requireConfig(database).costForNextLevel(currentLevel);
  }

  double multiplierForLevel({
    required int level,
    required GameDatabase database,
  }) {
    return requireConfig(database).multiplierForLevel(level);
  }

  EquipmentEnhancementResult enhance({
    required InventoryState state,
    required String instanceId,
    required GameDatabase database,
    bool dryRun = false,
  }) {
    final equipment = state.equipmentInstances[instanceId];
    if (equipment == null) {
      return EquipmentEnhancementResult(
        accepted: false,
        reason: EquipmentEnhancementReason.equipmentNotFound,
        state: state,
        instanceId: instanceId,
        previousLevel: 0,
        newLevel: 0,
        consumedMaterials: const [],
        consumedGold: 0,
      );
    }

    late final EnhancementConfig config;
    try {
      config = requireConfig(database);
    } on Object {
      return EquipmentEnhancementResult(
        accepted: false,
        reason: EquipmentEnhancementReason.invalidConfig,
        state: state,
        instanceId: instanceId,
        previousLevel: equipment.enhanceLevel,
        newLevel: equipment.enhanceLevel,
        consumedMaterials: const [],
        consumedGold: 0,
      );
    }
    if (equipment.enhanceLevel >= config.maxLevel) {
      return EquipmentEnhancementResult(
        accepted: false,
        reason: EquipmentEnhancementReason.maxLevelReached,
        state: state,
        instanceId: instanceId,
        previousLevel: equipment.enhanceLevel,
        newLevel: equipment.enhanceLevel,
        consumedMaterials: const [],
        consumedGold: 0,
      );
    }

    late final EnhancementCost cost;
    try {
      cost = config.costForNextLevel(equipment.enhanceLevel);
    } on Object {
      return EquipmentEnhancementResult(
        accepted: false,
        reason: EquipmentEnhancementReason.invalidConfig,
        state: state,
        instanceId: instanceId,
        previousLevel: equipment.enhanceLevel,
        newLevel: equipment.enhanceLevel,
        consumedMaterials: const [],
        consumedGold: 0,
      );
    }

    if (_materialQuantity(state, _goldMaterialId) < cost.gold) {
      return EquipmentEnhancementResult(
        accepted: false,
        reason: EquipmentEnhancementReason.insufficientGold,
        state: state,
        instanceId: instanceId,
        previousLevel: equipment.enhanceLevel,
        newLevel: equipment.enhanceLevel,
        consumedMaterials: const [],
        consumedGold: 0,
      );
    }
    if (_materialQuantity(state, _dustMaterialId) < cost.dust) {
      return EquipmentEnhancementResult(
        accepted: false,
        reason: EquipmentEnhancementReason.insufficientDust,
        state: state,
        instanceId: instanceId,
        previousLevel: equipment.enhanceLevel,
        newLevel: equipment.enhanceLevel,
        consumedMaterials: const [],
        consumedGold: 0,
      );
    }

    if (dryRun) {
      return EquipmentEnhancementResult(
        accepted: true,
        reason: EquipmentEnhancementReason.enhanced,
        state: state,
        instanceId: instanceId,
        previousLevel: equipment.enhanceLevel,
        newLevel: equipment.enhanceLevel + 1,
        consumedMaterials: [
          MaterialStack(materialId: _dustMaterialId, quantity: cost.dust),
        ],
        consumedGold: cost.gold,
      );
    }

    final nextEquipment = equipment.copyWith(
      enhanceLevel: equipment.enhanceLevel + 1,
    );
    final nextInstances = {
      ...state.equipmentInstances,
      instanceId: nextEquipment,
    };
    final nextMaterials = _consumeMaterial(
      _consumeMaterial(state.materials, _goldMaterialId, cost.gold),
      _dustMaterialId,
      cost.dust,
    );

    return EquipmentEnhancementResult(
      accepted: true,
      reason: EquipmentEnhancementReason.enhanced,
      state: state.copyWith(
        equipmentInstances: nextInstances,
        materials: nextMaterials,
      ),
      instanceId: instanceId,
      previousLevel: equipment.enhanceLevel,
      newLevel: nextEquipment.enhanceLevel,
      consumedMaterials: [
        MaterialStack(materialId: _dustMaterialId, quantity: cost.dust),
      ],
      consumedGold: cost.gold,
      message: 'Enhanced to +${nextEquipment.enhanceLevel}',
    );
  }

  int _materialQuantity(InventoryState state, String materialId) {
    return state.materials
        .where((material) => material.materialId == materialId)
        .fold<int>(0, (sum, material) => sum + material.quantity);
  }

  List<MaterialStack> _consumeMaterial(
    List<MaterialStack> materials,
    String materialId,
    int quantity,
  ) {
    var remaining = quantity;
    final result = <MaterialStack>[];
    for (final material in materials) {
      if (material.materialId != materialId || remaining <= 0) {
        result.add(material);
        continue;
      }

      final consumed =
          material.quantity < remaining ? material.quantity : remaining;
      final nextQuantity = material.quantity - consumed;
      remaining -= consumed;
      if (nextQuantity > 0) {
        result.add(material.copyWith(quantity: nextQuantity));
      }
    }

    return List.unmodifiable(result);
  }
}

class EquipmentEnhancementResult {
  const EquipmentEnhancementResult({
    required this.accepted,
    required this.reason,
    required this.state,
    required this.instanceId,
    required this.previousLevel,
    required this.newLevel,
    required this.consumedMaterials,
    required this.consumedGold,
    this.message,
  });

  final bool accepted;
  final EquipmentEnhancementReason reason;
  final InventoryState state;
  final String instanceId;
  final int previousLevel;
  final int newLevel;
  final List<MaterialStack> consumedMaterials;
  final int consumedGold;
  final String? message;
}

enum EquipmentEnhancementReason {
  enhanced,
  equipmentNotFound,
  maxLevelReached,
  insufficientDust,
  insufficientGold,
  invalidConfig,
}

const _goldMaterialId = BattleSettlementService.goldMaterialId;
const _dustMaterialId = EquipmentInventoryActionService.salvageDustMaterialId;
