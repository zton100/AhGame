import '../../models/equipment_template.dart';
import '../../models/inventory_state.dart';
import '../config/game_database.dart';
import 'equipment_enhancement_service.dart';

class AutoEnhancementService {
  const AutoEnhancementService({
    EquipmentEnhancementService enhancementService =
        const EquipmentEnhancementService(),
  }) : _enhancementService = enhancementService;

  final EquipmentEnhancementService _enhancementService;

  AutoEnhancementRecommendation recommend({
    required InventoryState inventory,
    required GameDatabase database,
  }) {
    final equippedIds = inventory.equipmentLoadout.equippedBySlot;
    if (equippedIds.isEmpty) {
      return const AutoEnhancementRecommendation(
        accepted: false,
        reason: AutoEnhancementReason.noEquippedEquipment,
      );
    }

    final candidates = [
      if (equippedIds[EquipmentSlot.mainWeapon.id] != null)
        equippedIds[EquipmentSlot.mainWeapon.id]!,
      for (final entry in equippedIds.entries)
        if (entry.key != EquipmentSlot.mainWeapon.id) entry.value,
    ];

    String? bestId;
    var bestLevel = 1 << 30;
    EquipmentEnhancementResult? bestPreview;
    for (final instanceId in candidates.toSet()) {
      final equipment = inventory.equipmentInstances[instanceId];
      if (equipment == null) {
        continue;
      }
      final preview = _enhancementService.enhance(
        state: inventory,
        instanceId: instanceId,
        database: database,
        dryRun: true,
      );
      if (!preview.accepted) {
        bestPreview ??= preview;
        continue;
      }
      if (equipment.enhanceLevel < bestLevel) {
        bestId = instanceId;
        bestLevel = equipment.enhanceLevel;
        bestPreview = preview;
      }
    }

    if (bestId == null || bestPreview == null || !bestPreview.accepted) {
      return AutoEnhancementRecommendation(
        accepted: false,
        reason: _mapFailure(bestPreview?.reason),
      );
    }

    return AutoEnhancementRecommendation(
      accepted: true,
      reason: AutoEnhancementReason.recommended,
      instanceId: bestId,
      preview: bestPreview,
    );
  }

  EquipmentEnhancementResult enhanceRecommended({
    required InventoryState inventory,
    required GameDatabase database,
  }) {
    final recommendation = recommend(inventory: inventory, database: database);
    if (!recommendation.accepted || recommendation.instanceId == null) {
      return EquipmentEnhancementResult(
        accepted: false,
        reason: _mapReason(recommendation.reason),
        state: inventory,
        instanceId: recommendation.instanceId ?? '',
        previousLevel: 0,
        newLevel: 0,
        consumedMaterials: const [],
        consumedGold: 0,
      );
    }

    return _enhancementService.enhance(
      state: inventory,
      instanceId: recommendation.instanceId!,
      database: database,
    );
  }

  AutoEnhancementReason _mapFailure(EquipmentEnhancementReason? reason) {
    switch (reason) {
      case EquipmentEnhancementReason.insufficientDust:
        return AutoEnhancementReason.insufficientDust;
      case EquipmentEnhancementReason.insufficientGold:
        return AutoEnhancementReason.insufficientGold;
      case EquipmentEnhancementReason.maxLevelReached:
        return AutoEnhancementReason.allEquippedAtMaxLevel;
      case EquipmentEnhancementReason.invalidConfig:
        return AutoEnhancementReason.invalidConfig;
      case EquipmentEnhancementReason.equipmentNotFound:
      case EquipmentEnhancementReason.enhanced:
      case null:
        return AutoEnhancementReason.noEnhanceableEquipment;
    }
  }

  EquipmentEnhancementReason _mapReason(AutoEnhancementReason reason) {
    switch (reason) {
      case AutoEnhancementReason.insufficientDust:
        return EquipmentEnhancementReason.insufficientDust;
      case AutoEnhancementReason.insufficientGold:
        return EquipmentEnhancementReason.insufficientGold;
      case AutoEnhancementReason.allEquippedAtMaxLevel:
        return EquipmentEnhancementReason.maxLevelReached;
      case AutoEnhancementReason.invalidConfig:
        return EquipmentEnhancementReason.invalidConfig;
      case AutoEnhancementReason.noEquippedEquipment:
      case AutoEnhancementReason.noEnhanceableEquipment:
      case AutoEnhancementReason.recommended:
        return EquipmentEnhancementReason.equipmentNotFound;
    }
  }
}

class AutoEnhancementRecommendation {
  const AutoEnhancementRecommendation({
    required this.accepted,
    required this.reason,
    this.instanceId,
    this.preview,
  });

  final bool accepted;
  final AutoEnhancementReason reason;
  final String? instanceId;
  final EquipmentEnhancementResult? preview;
}

enum AutoEnhancementReason {
  recommended,
  noEquippedEquipment,
  noEnhanceableEquipment,
  allEquippedAtMaxLevel,
  insufficientDust,
  insufficientGold,
  invalidConfig,
}
