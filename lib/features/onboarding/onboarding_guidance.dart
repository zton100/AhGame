import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/inventory_state.dart';
import '../../models/save_data.dart';

enum OnboardingGuidancePage {
  battle,
  equipment,
  character,
}

class OnboardingGoal {
  const OnboardingGoal({
    required this.title,
    required this.completed,
  });

  final String title;
  final bool completed;
}

class OnboardingGuidance {
  const OnboardingGuidance({
    required this.title,
    required this.message,
    required this.actionText,
    required this.goals,
  });

  final String title;
  final String message;
  final String actionText;
  final List<OnboardingGoal> goals;
}

class OnboardingGuidanceFactory {
  const OnboardingGuidanceFactory();

  OnboardingGuidance create({
    required SaveData saveData,
    required InventoryState inventory,
    required OnboardingGuidancePage page,
  }) {
    final goals = _goals(saveData, inventory);
    final hasCompletedBattle = goals[0].completed;
    final hasEquipment = goals[1].completed;
    final hasEquipped = goals[2].completed;
    final hasEnhanced = goals[3].completed;
    final hasDust = _materialQuantity(inventory, 'salvage_dust') > 0;
    final hasGold = _materialQuantity(inventory, 'gold') > 0;
    final canEnhance = hasDust && hasGold;

    return switch (page) {
      OnboardingGuidancePage.battle => _battleGuidance(
          goals: goals,
          hasCompletedBattle: hasCompletedBattle,
          hasEquipment: hasEquipment,
          hasEquipped: hasEquipped,
          hasEnhanced: hasEnhanced,
          canEnhance: canEnhance,
        ),
      OnboardingGuidancePage.equipment => _equipmentGuidance(
          goals: goals,
          hasEquipment: hasEquipment,
          hasEquipped: hasEquipped,
          hasEnhanced: hasEnhanced,
          canEnhance: canEnhance,
        ),
      OnboardingGuidancePage.character => _characterGuidance(
          goals: goals,
          hasEquipment: hasEquipment,
          hasEquipped: hasEquipped,
          hasEnhanced: hasEnhanced,
          canEnhance: canEnhance,
        ),
    };
  }

  OnboardingGuidance _battleGuidance({
    required List<OnboardingGoal> goals,
    required bool hasCompletedBattle,
    required bool hasEquipment,
    required bool hasEquipped,
    required bool hasEnhanced,
    required bool canEnhance,
  }) {
    if (!hasCompletedBattle) {
      return OnboardingGuidance(
        title: '新手目标',
        message: '先点击运行 10 场，拿到第一批经验、金币和装备。',
        actionText: '优先操作：运行 10 场战斗',
        goals: goals,
      );
    }
    if (hasEquipment && !hasEquipped) {
      return OnboardingGuidance(
        title: '新手目标',
        message: '背包已经有装备，下一步去装备页穿戴推荐装备。',
        actionText: '优先操作：穿戴推荐装备',
        goals: goals,
      );
    }
    if (canEnhance && !hasEnhanced) {
      return OnboardingGuidance(
        title: '新手目标',
        message: '材料已经能用于强化，优先强化已穿戴装备。',
        actionText: '优先操作：强化主力装备',
        goals: goals,
      );
    }
    return OnboardingGuidance(
      title: '新手目标',
      message: '当前成长链路已启动，继续自动战斗并观察是否需要刷旧关。',
      actionText: '优先操作：继续推进或刷材料',
      goals: goals,
    );
  }

  OnboardingGuidance _equipmentGuidance({
    required List<OnboardingGoal> goals,
    required bool hasEquipment,
    required bool hasEquipped,
    required bool hasEnhanced,
    required bool canEnhance,
  }) {
    if (!hasEquipment) {
      return OnboardingGuidance(
        title: '装备引导',
        message: '背包还是空的，先去战斗页运行 10 场获得装备。',
        actionText: '优先操作：去战斗页刷第一批装备',
        goals: goals,
      );
    }
    if (!hasEquipped) {
      return OnboardingGuidance(
        title: '装备引导',
        message: '先把推荐装备穿上，角色属性会立刻提高。',
        actionText: '优先操作：穿戴推荐装备',
        goals: goals,
      );
    }
    if (canEnhance && !hasEnhanced) {
      return OnboardingGuidance(
        title: '装备引导',
        message: '已有金币和分解粉尘，可以强化已穿戴装备。',
        actionText: '优先操作：强化推荐穿戴装备',
        goals: goals,
      );
    }
    return OnboardingGuidance(
      title: '装备引导',
      message: '保留高价值装备，低价值装备可以交给自动分解。',
      actionText: '优先操作：继续筛选、锁定和强化',
      goals: goals,
    );
  }

  OnboardingGuidance _characterGuidance({
    required List<OnboardingGoal> goals,
    required bool hasEquipment,
    required bool hasEquipped,
    required bool hasEnhanced,
    required bool canEnhance,
  }) {
    if (!hasEquipment) {
      return OnboardingGuidance(
        title: '成长建议',
        message: '当前短板：还没有装备。先通过战斗获得第一批装备。',
        actionText: '下一步：运行 10 场战斗',
        goals: goals,
      );
    }
    if (!hasEquipped) {
      return OnboardingGuidance(
        title: '成长建议',
        message: '当前短板：装备空缺。先穿戴背包里的推荐装备。',
        actionText: '下一步：去装备页穿戴装备',
        goals: goals,
      );
    }
    if (canEnhance && !hasEnhanced) {
      return OnboardingGuidance(
        title: '成长建议',
        message: '当前短板：装备强化不足。优先强化武器、生命或护甲装备。',
        actionText: '下一步：强化主力装备',
        goals: goals,
      );
    }
    return OnboardingGuidance(
      title: '成长建议',
      message: '角色已经进入刷装和强化循环，继续观察输出与生存是否卡关。',
      actionText: '下一步：继续战斗并升级装备',
      goals: goals,
    );
  }

  List<OnboardingGoal> _goals(SaveData saveData, InventoryState inventory) {
    final hasCompletedBattle = saveData.playerProgress.experience > 0 ||
        inventory.materials.isNotEmpty ||
        inventory.equipmentInstanceIds.isNotEmpty;
    final hasEquipment = inventory.equipmentInstanceIds.isNotEmpty;
    final hasEquipped = inventory.equipmentLoadout.equippedBySlot.isNotEmpty;
    final hasEnhanced = inventory.equipmentInstances.values.any(
      (equipment) => equipment.enhanceLevel > 0,
    );
    final advancedStage = saveData.playerProgress.currentStageId !=
            PlayerProgress.defaultStageId ||
        saveData.playerProgress.highestClearedStageId != null;

    return [
      OnboardingGoal(title: '完成一次战斗', completed: hasCompletedBattle),
      OnboardingGoal(title: '获得一件装备', completed: hasEquipment),
      OnboardingGoal(title: '穿戴一件装备', completed: hasEquipped),
      OnboardingGoal(title: '强化一件装备', completed: hasEnhanced),
      OnboardingGoal(title: '推进到下一关', completed: advancedStage),
    ];
  }

  int _materialQuantity(InventoryState inventory, String materialId) {
    var total = 0;
    for (final material in inventory.materials) {
      if (material.materialId == materialId) {
        total += material.quantity;
      }
    }
    return total;
  }
}

class OnboardingGuidancePanel extends StatelessWidget {
  const OnboardingGuidancePanel({
    super.key,
    required this.guidance,
  });

  final OnboardingGuidance guidance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
        color: AppTheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(guidance.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(guidance.message),
          const SizedBox(height: 6),
          Text(
            guidance.actionText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final goal in guidance.goals) _GoalChip(goal: goal),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({required this.goal});

  final OnboardingGoal goal;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(
        goal.completed ? Icons.check_circle : Icons.radio_button_unchecked,
        size: 16,
        color: goal.completed ? AppTheme.primary : AppTheme.textMuted,
      ),
      label: Text(goal.title),
    );
  }
}
