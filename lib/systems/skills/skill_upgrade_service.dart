import '../../models/inventory_state.dart';
import '../../models/save_data.dart';
import 'skill_service.dart';

class SkillUpgradeService {
  const SkillUpgradeService({
    this.maxLevel = 10,
    this.baseGoldCost = 20,
  });

  final int maxLevel;
  final int baseGoldCost;

  int levelFor({
    required PlayerProgress progress,
    required String skillId,
  }) {
    return progress.skillLevels[skillId] ?? 1;
  }

  int goldCostForNextLevel({
    required PlayerProgress progress,
    required String skillId,
  }) {
    final currentLevel = levelFor(progress: progress, skillId: skillId);
    return currentLevel * baseGoldCost;
  }

  SkillUpgradeResult upgrade({
    required SaveData saveData,
    required SkillService skillService,
    required String skillId,
  }) {
    if (!skillService.validateSkillForClass(
      skillId: skillId,
      classId: saveData.playerProgress.currentClassId,
    )) {
      return SkillUpgradeResult(
        accepted: false,
        reason: SkillUpgradeReason.skillNotAllowed,
        saveData: saveData,
        skillId: skillId,
        previousLevel: levelFor(
          progress: saveData.playerProgress,
          skillId: skillId,
        ),
        newLevel: levelFor(
          progress: saveData.playerProgress,
          skillId: skillId,
        ),
        consumedGold: 0,
      );
    }

    final currentLevel = levelFor(
      progress: saveData.playerProgress,
      skillId: skillId,
    );
    if (currentLevel >= maxLevel) {
      return SkillUpgradeResult(
        accepted: false,
        reason: SkillUpgradeReason.maxLevelReached,
        saveData: saveData,
        skillId: skillId,
        previousLevel: currentLevel,
        newLevel: currentLevel,
        consumedGold: 0,
      );
    }

    final cost = goldCostForNextLevel(
      progress: saveData.playerProgress,
      skillId: skillId,
    );
    final currentGold = _materialQuantity(saveData.inventory.materials, 'gold');
    if (currentGold < cost) {
      return SkillUpgradeResult(
        accepted: false,
        reason: SkillUpgradeReason.insufficientGold,
        saveData: saveData,
        skillId: skillId,
        previousLevel: currentLevel,
        newLevel: currentLevel,
        consumedGold: 0,
      );
    }

    final nextSave = saveData.copyWith(
      playerProgress: saveData.playerProgress.copyWith(
        skillLevels: {
          ...saveData.playerProgress.skillLevels,
          skillId: currentLevel + 1,
        },
      ),
      inventory: saveData.inventory.copyWith(
        materials: _consumeMaterial(
          saveData.inventory.materials,
          materialId: 'gold',
          quantity: cost,
        ),
      ),
    );

    return SkillUpgradeResult(
      accepted: true,
      reason: SkillUpgradeReason.upgraded,
      saveData: nextSave,
      skillId: skillId,
      previousLevel: currentLevel,
      newLevel: currentLevel + 1,
      consumedGold: cost,
    );
  }

  int _materialQuantity(List<MaterialStack> materials, String materialId) {
    return materials
        .where((material) => material.materialId == materialId)
        .fold<int>(0, (sum, material) => sum + material.quantity);
  }

  List<MaterialStack> _consumeMaterial(
    List<MaterialStack> materials, {
    required String materialId,
    required int quantity,
  }) {
    var remaining = quantity;
    final result = <MaterialStack>[];
    for (final material in materials) {
      if (material.materialId != materialId) {
        result.add(material);
        continue;
      }

      final consumed =
          remaining > material.quantity ? material.quantity : remaining;
      remaining -= consumed;
      final nextQuantity = material.quantity - consumed;
      if (nextQuantity > 0) {
        result.add(material.copyWith(quantity: nextQuantity));
      }
    }

    return result;
  }
}

class SkillUpgradeResult {
  const SkillUpgradeResult({
    required this.accepted,
    required this.reason,
    required this.saveData,
    required this.skillId,
    required this.previousLevel,
    required this.newLevel,
    required this.consumedGold,
  });

  final bool accepted;
  final SkillUpgradeReason reason;
  final SaveData saveData;
  final String skillId;
  final int previousLevel;
  final int newLevel;
  final int consumedGold;
}

enum SkillUpgradeReason {
  upgraded,
  skillNotAllowed,
  insufficientGold,
  maxLevelReached,
}
