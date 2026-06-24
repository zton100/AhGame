import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/save/player_save_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/character_state.dart';
import '../../models/inventory_state.dart';
import '../../models/stat_block.dart';
import '../../systems/character/character_service.dart';
import '../../systems/character/class_service.dart';
import '../../systems/config/game_database.dart';
import '../../systems/config/game_database_service.dart';
import '../../systems/stats/character_final_stats_service.dart';
import '../../systems/stats/stat_aggregation_service.dart';

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
    required this.character,
    required this.inventory,
    required this.database,
    required this.finalStats,
  });

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
        _Section(
          title: '已穿戴装备',
          children: [
            if (inventory.equipmentLoadout.equippedBySlot.isEmpty)
              const Text('暂无穿戴装备')
            else
              for (final entry
                  in inventory.equipmentLoadout.equippedBySlot.entries)
                Text('${entry.key}: ${_equipmentName(entry.value, database)}'),
          ],
        ),
        const SizedBox(height: 16),
        _Section(
          title: '属性 Breakdown',
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
            label: stat.id, value: _formatNumber(stats.valueForId(stat.id))),
    ];
  }

  String _equipmentName(String instanceId, GameDatabase database) {
    final equipment = inventory.equipmentInstances[instanceId];
    if (equipment == null) {
      return '$instanceId (missing)';
    }

    final template = database.findRecord(
      'equipment_templates',
      equipment.templateId,
    );
    return template?['name'] as String? ?? equipment.templateId;
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
      '${stat.id}: base ${_formatNumber(breakdown.base)}, flat ${_formatNumber(breakdown.flat)}, percent ${_formatNumber(breakdown.percent)}, final ${_formatNumber(breakdown.finalValue)}',
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
