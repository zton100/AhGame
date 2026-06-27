import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/save/player_save_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/character_state.dart';
import '../../models/inventory_state.dart';
import '../../models/save_data.dart';
import '../../models/stat_block.dart';
import '../../systems/character/character_service.dart';
import '../../systems/character/class_service.dart';
import '../../systems/config/game_database.dart';
import '../../systems/config/game_database_service.dart';
import '../../systems/skills/skill_effect_preview_service.dart';
import '../../systems/skills/skill_service.dart';
import '../../systems/skills/skill_upgrade_service.dart';
import '../../systems/stats/character_final_stats_service.dart';
import '../../systems/stats/stat_aggregation_service.dart';
import '../common/game_text_labels.dart';

class CharacterPage extends ConsumerWidget {
  const CharacterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saveLoad = ref.watch(playerSaveProvider);
    final databaseLoad = ref.watch(gameDatabaseLoadProvider);

    if (saveLoad.isLoading && !saveLoad.hasValue) {
      return const _CharacterMessage(
        title: '正在读取角色',
        message: '如果没有存档，会自动创建一个新角色。',
        icon: Icons.person_search_outlined,
      );
    }

    if (saveLoad.hasError && !saveLoad.hasValue) {
      return _CharacterMessage(
        title: '角色存档读取失败',
        message: saveLoad.error.toString(),
        icon: Icons.error_outline,
      );
    }

    final saveData = saveLoad.valueOrNull;
    if (saveData == null) {
      return const _CharacterMessage(
        title: '正在创建角色',
        message: '角色页会在存档准备完成后显示。',
        icon: Icons.hourglass_empty,
      );
    }

    return databaseLoad.when(
      data: (result) {
        final database = result.database;
        final character = CharacterService(
          classService: ClassService(database),
        ).restoreFromSave(saveData);
        final inventory = inventoryStateFromSave(saveData.inventory);
        final finalStats = const CharacterFinalStatsService().compute(
          character: character,
          loadout: inventory.equipmentLoadout,
          inventory: inventory,
          database: database,
        );

        return _CharacterPageContent(
          saveData: saveData,
          character: character,
          inventory: inventory,
          database: database,
          finalStats: finalStats,
        );
      },
      error: (error, _) {
        return _CharacterMessage(
          title: '角色数据加载失败',
          message: error.toString(),
          icon: Icons.error_outline,
        );
      },
      loading: () {
        return const _CharacterMessage(
          title: '正在加载角色数据',
          message: '职业和属性数据库加载中。',
          icon: Icons.hourglass_empty,
        );
      },
    );
  }
}

class _CharacterPageContent extends StatelessWidget {
  const _CharacterPageContent({
    required this.saveData,
    required this.character,
    required this.inventory,
    required this.database,
    required this.finalStats,
  });

  final SaveData saveData;
  final CharacterState character;
  final InventoryState inventory;
  final GameDatabase database;
  final CharacterFinalStatsResult finalStats;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('角色', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        _InfoRow(label: '当前职业', value: character.classConfig.name),
        _InfoRow(label: '等级', value: character.level.toString()),
        _InfoRow(label: '经验', value: character.experience.toString()),
        if (finalStats.warnings.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final warning in finalStats.warnings)
            _WarningBanner(message: warning.message),
        ],
        const SizedBox(height: 16),
        _Section(
          title: '基础属性',
          children: _statRows(character.levelStats),
        ),
        const SizedBox(height: 16),
        _Section(
          title: '最终属性',
          children: _statRows(finalStats.computedStats.finalStats),
        ),
        const SizedBox(height: 16),
        _SkillSection(
          saveData: saveData,
          database: database,
          finalStats: finalStats.computedStats,
        ),
        const SizedBox(height: 16),
        _Section(
          title: '已穿戴装备',
          children: [
            if (inventory.equipmentLoadout.equippedBySlot.isEmpty)
              const Text('暂无穿戴装备')
            else
              for (final entry
                  in inventory.equipmentLoadout.equippedBySlot.entries)
                Text(
                  '${slotLabel(entry.key)}: ${_equipmentName(entry.value, database)}',
                ),
          ],
        ),
        const SizedBox(height: 16),
        _Section(
          title: '属性明细',
          children: [
            for (final stat in StatKey.values)
              _BreakdownLine(
                stat: stat,
                breakdown: finalStats.computedStats.breakdownFor(stat),
              ),
          ],
        ),
      ],
    );
  }

  List<Widget> _statRows(StatBlock stats) {
    return [
      for (final stat in StatKey.values)
        _InfoRow(
          label: statLabel(stat.id),
          value: _formatNumber(stats.valueForId(stat.id)),
        ),
    ];
  }

  String _equipmentName(String instanceId, GameDatabase database) {
    final equipment = inventory.equipmentInstances[instanceId];
    if (equipment == null) {
      return '$instanceId（缺失）';
    }

    final template = database.findRecord(
      'equipment_templates',
      equipment.templateId,
    );
    return template?['name'] as String? ?? equipment.templateId;
  }
}

class _SkillSection extends ConsumerWidget {
  const _SkillSection({
    required this.saveData,
    required this.database,
    required this.finalStats,
  });

  final SaveData saveData;
  final GameDatabase database;
  final ComputedStats finalStats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillService = SkillService(database);
    final upgradeService = const SkillUpgradeService();
    final previewService = const SkillEffectPreviewService();
    final skillIds = saveData.playerProgress.skillLoadout.activeSkillIds;

    return _Section(
      title: '技能',
      children: [
        if (skillIds.isEmpty)
          const Text('暂无主动技能')
        else
          for (final skillId in skillIds)
            _SkillUpgradeRow(
              skillId: skillId,
              skillName: skillService.requireSkill(skillId).name,
              level: upgradeService.levelFor(
                progress: saveData.playerProgress,
                skillId: skillId,
              ),
              nextGoldCost: upgradeService.goldCostForNextLevel(
                progress: saveData.playerProgress,
                skillId: skillId,
              ),
              previewDamage: previewService
                  .previewDamage(
                    skill: skillService.requireSkill(skillId),
                    stats: finalStats,
                    skillLevel: upgradeService.levelFor(
                      progress: saveData.playerProgress,
                      skillId: skillId,
                    ),
                  )
                  .damage,
              onUpgrade: () => _upgradeSkill(context, ref, skillId),
            ),
      ],
    );
  }

  Future<void> _upgradeSkill(
    BuildContext context,
    WidgetRef ref,
    String skillId,
  ) async {
    final result = await ref.read(playerSaveProvider.notifier).upgradeSkill(
          database: database,
          skillId: skillId,
        );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.accepted
              ? '技能已升级到 ${result.newLevel} 级'
              : _skillUpgradeFailureMessage(result.reason),
        ),
      ),
    );
  }
}

class _SkillUpgradeRow extends StatelessWidget {
  const _SkillUpgradeRow({
    required this.skillId,
    required this.skillName,
    required this.level,
    required this.nextGoldCost,
    required this.previewDamage,
    required this.onUpgrade,
  });

  final String skillId;
  final String skillName;
  final int level;
  final int nextGoldCost;
  final double previewDamage;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('$skillName $level 级'),
          Text('预览伤害 ${_formatNumber(previewDamage)}'),
          Text('下级消耗 $nextGoldCost 金币'),
          FilledButton.tonal(
            onPressed: onUpgrade,
            child: const Text('升级技能'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.surfaceRaised),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _BreakdownLine extends StatelessWidget {
  const _BreakdownLine({
    required this.stat,
    required this.breakdown,
  });

  final StatKey stat;
  final StatBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${statLabel(stat.id)}: 基础 ${_formatNumber(breakdown.base)}，固定 ${_formatNumber(breakdown.flat)}，百分比 ${_formatNumber(breakdown.percent)}，最终 ${_formatNumber(breakdown.finalValue)}',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(message),
      ),
    );
  }
}

class _CharacterMessage extends StatelessWidget {
  const _CharacterMessage({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppTheme.primary),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(2);
}

String _skillUpgradeFailureMessage(SkillUpgradeReason reason) {
  switch (reason) {
    case SkillUpgradeReason.insufficientGold:
      return '金币不足，无法升级技能。';
    case SkillUpgradeReason.maxLevelReached:
      return '技能已达到最高等级。';
    case SkillUpgradeReason.skillNotAllowed:
      return '当前职业不能使用该技能。';
    case SkillUpgradeReason.upgraded:
      return '技能已升级。';
  }
}
