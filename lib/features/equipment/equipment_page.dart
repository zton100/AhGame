import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/save/player_save_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/auto_salvage_config.dart';
import '../../models/inventory_state.dart';
import '../../models/save_data.dart';
import '../../systems/config/game_database.dart';
import '../../systems/config/game_database_service.dart';
import '../../systems/equipment/equipment_enhancement_service.dart';
import '../../systems/inventory/equipment_inventory_action_service.dart';
import 'equipment_card_view_model.dart';
import 'equipment_page_view_model.dart';

class EquipmentPage extends ConsumerStatefulWidget {
  const EquipmentPage({super.key});

  @override
  ConsumerState<EquipmentPage> createState() => _EquipmentPageState();
}

class _EquipmentPageState extends ConsumerState<EquipmentPage> {
  var _isGeneratingTestEquipment = false;
  var _filter = EquipmentPageFilter.all;
  var _sort = EquipmentPageSort.newestFirst;

  @override
  Widget build(BuildContext context) {
    final databaseLoad = ref.watch(gameDatabaseLoadProvider);
    final saveLoad = ref.watch(playerSaveProvider);

    if (saveLoad.isLoading && !saveLoad.hasValue) {
      return const _EquipmentMessage(
        title: '正在读取存档',
        message: '如果没有存档，会自动创建一个新存档。',
        icon: Icons.save_outlined,
      );
    }

    if (saveLoad.hasError && !saveLoad.hasValue) {
      return _EquipmentMessage(
        title: '存档读取失败',
        message: saveLoad.error.toString(),
        icon: Icons.error_outline,
      );
    }

    final saveData = saveLoad.valueOrNull;
    if (saveData == null) {
      return const _EquipmentMessage(
        title: '正在创建存档',
        message: '装备页会在存档准备完成后显示背包内容。',
        icon: Icons.hourglass_empty,
      );
    }

    return databaseLoad.when(
      data: (result) {
        final inventory = inventoryStateFromSave(saveData.inventory);
        final viewModel = const EquipmentPageViewModelFactory().create(
          inventory: inventory,
          database: result.database,
          classId: saveData.playerProgress.currentClassId,
        );
        return _EquipmentPageContent(
          viewModel: viewModel,
          saveData: saveData,
          database: result.database,
          filter: _filter,
          sort: _sort,
          onFilterChanged: (filter) => setState(() => _filter = filter),
          onSortChanged: (sort) => setState(() => _sort = sort),
          debugAction: _DebugGenerateButton(
            isGenerating: _isGeneratingTestEquipment,
            onPressed: _isGeneratingTestEquipment
                ? null
                : () => _generateTestEquipment(result.database),
          ),
        );
      },
      error: (error, _) {
        return _EquipmentMessage(
          title: '装备数据加载失败',
          message: error.toString(),
          icon: Icons.error_outline,
        );
      },
      loading: () {
        return const _EquipmentMessage(
          title: '正在整理装备',
          message: '装备数据库加载中。',
          icon: Icons.hourglass_empty,
        );
      },
    );
  }

  Future<void> _generateTestEquipment(GameDatabase database) async {
    setState(() => _isGeneratingTestEquipment = true);
    try {
      await ref.read(playerSaveProvider.notifier).generateTestEquipment(
            database,
          );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('生成测试装备失败：$error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingTestEquipment = false);
      }
    }
  }
}

class _EquipmentPageContent extends StatelessWidget {
  const _EquipmentPageContent({
    required this.viewModel,
    required this.saveData,
    required this.database,
    required this.filter,
    required this.sort,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.debugAction,
  });

  final EquipmentPageViewModel viewModel;
  final SaveData saveData;
  final GameDatabase database;
  final EquipmentPageFilter filter;
  final EquipmentPageSort sort;
  final ValueChanged<EquipmentPageFilter> onFilterChanged;
  final ValueChanged<EquipmentPageSort> onSortChanged;
  final Widget debugAction;

  @override
  Widget build(BuildContext context) {
    final visibleItems = viewModel.visibleItems(filter: filter, sort: sort);
    if (viewModel.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child:
                    Text('装备', style: Theme.of(context).textTheme.titleLarge),
              ),
              debugAction,
            ],
          ),
          const SizedBox(height: 12),
          _EquipmentControls(
            config: saveData.inventory.autoSalvageConfig,
            filter: filter,
            sort: sort,
            visibleItems: visibleItems,
            database: database,
            onFilterChanged: onFilterChanged,
            onSortChanged: onSortChanged,
          ),
          const SizedBox(height: 16),
          const _EquipmentMessage(
            title: '背包暂无装备',
            message: '击败敌人后获得的装备会出现在这里。',
            icon: Icons.inventory_2_outlined,
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('装备', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    '背包 ${viewModel.items.length} 件装备',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            debugAction,
          ],
        ),
        if (viewModel.missingInstanceIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          _WarningBanner(
            message: '有 ${viewModel.missingInstanceIds.length} 件装备缺少完整实例数据。',
          ),
        ],
        const SizedBox(height: 12),
        _EquipmentControls(
          config: saveData.inventory.autoSalvageConfig,
          filter: filter,
          sort: sort,
          visibleItems: visibleItems,
          database: database,
          onFilterChanged: onFilterChanged,
          onSortChanged: onSortChanged,
        ),
        const SizedBox(height: 12),
        if (visibleItems.isEmpty)
          const _WarningBanner(message: '当前筛选没有装备。')
        else
          for (final item in visibleItems) ...[
            _EquipmentCard(item: item, database: database),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _EquipmentControls extends ConsumerWidget {
  const _EquipmentControls({
    required this.config,
    required this.filter,
    required this.sort,
    required this.visibleItems,
    required this.database,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  final AutoSalvageConfig config;
  final EquipmentPageFilter filter;
  final EquipmentPageSort sort;
  final List<EquipmentPageItemViewModel> visibleItems;
  final GameDatabase database;
  final ValueChanged<EquipmentPageFilter> onFilterChanged;
  final ValueChanged<EquipmentPageSort> onSortChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Panel(
      title: 'Auto Salvage / Filter',
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Enable Auto Salvage'),
          value: config.enabled,
          onChanged: (enabled) => _updateConfig(
            ref,
            config.copyWith(enabled: enabled),
          ),
        ),
        Text(
          '开启后会自动处理背包中符合规则的全部低价值装备，不只处理新掉落装备。锁定、已穿戴、高品质和高 BD 匹配装备会默认保留。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<String>(
              value: config.minQualityToKeep,
              items: const [
                DropdownMenuItem(value: 'normal', child: Text('Keep Normal+')),
                DropdownMenuItem(value: 'magic', child: Text('Keep Magic+')),
                DropdownMenuItem(value: 'rare', child: Text('Keep Rare+')),
                DropdownMenuItem(value: 'epic', child: Text('Keep Epic+')),
                DropdownMenuItem(
                  value: 'legendary',
                  child: Text('Keep Legendary+'),
                ),
              ],
              onChanged: (qualityId) {
                if (qualityId == null) {
                  return;
                }
                _updateConfig(
                  ref,
                  config.copyWith(minQualityToKeep: qualityId),
                );
              },
            ),
            SizedBox(
              width: 180,
              child: TextFormField(
                key: ValueKey(config.minBuildMatchScoreToKeep),
                initialValue:
                    config.minBuildMatchScoreToKeep.toStringAsFixed(0),
                decoration: const InputDecoration(
                  labelText: 'Min BD score',
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onFieldSubmitted: (value) {
                  final score = double.tryParse(value);
                  if (score == null) {
                    return;
                  }
                  _updateConfig(
                    ref,
                    config.copyWith(minBuildMatchScoreToKeep: score),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<EquipmentPageFilter>(
              value: filter,
              items: [
                for (final value in EquipmentPageFilter.values)
                  DropdownMenuItem(value: value, child: Text(value.label)),
              ],
              onChanged: (value) {
                if (value != null) {
                  onFilterChanged(value);
                }
              },
            ),
            DropdownButton<EquipmentPageSort>(
              value: sort,
              items: [
                for (final value in EquipmentPageSort.values)
                  DropdownMenuItem(value: value, child: Text(value.label)),
              ],
              onChanged: (value) {
                if (value != null) {
                  onSortChanged(value);
                }
              },
            ),
            OutlinedButton(
              onPressed: visibleItems.isEmpty
                  ? null
                  : () => _salvageFiltered(context, ref),
              child: const Text('Salvage filtered low-value'),
            ),
            FilledButton.tonal(
              onPressed: () => _enhanceRecommended(context, ref),
              child: const Text('Enhance recommended equipped'),
            ),
            FilledButton.tonal(
              onPressed: () => _equipRecommended(context, ref),
              child: const Text('Equip recommended upgrade'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _updateConfig(
    WidgetRef ref,
    AutoSalvageConfig next,
  ) async {
    await ref.read(playerSaveProvider.notifier).updateAutoSalvageConfig(next);
  }

  Future<void> _salvageFiltered(BuildContext context, WidgetRef ref) async {
    final report =
        await ref.read(playerSaveProvider.notifier).autoSalvageEquipment(
      database: database,
      candidateInstanceIds: [
        for (final item in visibleItems) item.equipment.instanceId,
      ],
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Auto salvaged ${report.salvagedCount}, gained ${_materialsText(report.gainedMaterials)}',
        ),
      ),
    );
  }

  Future<void> _enhanceRecommended(BuildContext context, WidgetRef ref) async {
    final result =
        await ref.read(playerSaveProvider.notifier).enhanceRecommendedEquipment(
              database: database,
            );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.accepted
              ? 'Enhanced recommended equipment to +${result.newLevel}'
              : _enhancementFailureMessage(result.reason),
        ),
      ),
    );
  }

  Future<void> _equipRecommended(BuildContext context, WidgetRef ref) async {
    final result =
        await ref.read(playerSaveProvider.notifier).equipRecommendedUpgrade(
              database: database,
            );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.accepted
              ? 'Equipped recommended ${result.candidate?.template.name ?? 'upgrade'}'
              : 'No recommended equipment upgrade found.',
        ),
      ),
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  const _EquipmentCard({
    required this.item,
    required this.database,
  });

  final EquipmentPageItemViewModel item;
  final GameDatabase database;

  @override
  Widget build(BuildContext context) {
    final card = item.card;
    final qualityColor = Color(card.qualityColorValue);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showEquipmentDetails(context, item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.equipment.enhanceLevel > 0
                              ? '${card.title} +${item.equipment.enhanceLevel}'
                              : card.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: qualityColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${card.qualityLabel} / ${item.slotLabel}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  _ScorePill(score: card.matchScore),
                ],
              ),
              const SizedBox(height: 12),
              _StatWrap(stats: card.baseStats),
              if (card.affixes.isNotEmpty) ...[
                const SizedBox(height: 10),
                for (final affix in card.affixes.take(3))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _affixLine(affix),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
              const SizedBox(height: 12),
              _TagRow(
                matchedTags: card.matchedTags,
                rejectedTags: card.rejectedTags,
              ),
              if (item.isLocked || item.isEquipped) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (item.isEquipped)
                      const _Chip(label: '已穿戴', color: AppTheme.primary),
                    if (item.isLocked)
                      const _Chip(label: '已锁定', color: AppTheme.danger),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showEquipmentDetails(
    BuildContext context,
    EquipmentPageItemViewModel item,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => _EquipmentDetailDialog(
        item: item,
        database: database,
      ),
    );
  }
}

class _EquipmentDetailDialog extends ConsumerWidget {
  const _EquipmentDetailDialog({
    required this.item,
    required this.database,
  });

  final EquipmentPageItemViewModel item;
  final GameDatabase database;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = item.card;
    final qualityColor = Color(card.qualityColorValue);

    return AlertDialog(
      title: Text(
        card.title,
        style: TextStyle(color: qualityColor),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${card.qualityLabel} / ${item.slotLabel}'),
            const SizedBox(height: 12),
            _DetailSection(
              title: '基础属性',
              children: [
                for (final stat in card.baseStats)
                  Text('${stat.label}: ${_formatNumber(stat.value)}'),
              ],
            ),
            const SizedBox(height: 12),
            _DetailSection(
              title: '词缀',
              children: [
                if (card.affixes.isEmpty)
                  const Text('无词缀')
                else
                  for (final affix in card.affixes) Text(_affixLine(affix)),
              ],
            ),
            const SizedBox(height: 12),
            _DetailSection(
              title: 'BD 匹配',
              children: [
                Text('匹配分: ${card.matchScore.toStringAsFixed(1)}'),
                Text('匹配变化: ${_signed(card.matchScoreDelta)}'),
                Text('攻击变化: ${_signed(card.attackDelta)}'),
                Text('推荐: ${card.recommendationLabel}'),
                Text('matchedTags: ${_tags(card.matchedTags)}'),
                Text('rejectedTags: ${_tags(card.rejectedTags)}'),
              ],
            ),
            const SizedBox(height: 12),
            _EnhancementSection(item: item, database: database),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _enhance(context, ref),
          child: const Text('Enhance'),
        ),
        TextButton(
          onPressed: () => _equip(context, ref),
          child: const Text('穿戴'),
        ),
        TextButton(
          onPressed: () => _toggleLock(context, ref),
          child: Text(item.isLocked ? '解锁' : '锁定'),
        ),
        TextButton(
          onPressed: () => _salvage(context, ref),
          child: const Text('分解'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Future<void> _equip(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(playerSaveProvider.notifier).equipEquipment(
            database: database,
            instanceId: item.equipment.instanceId,
          );
      if (!context.mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已穿戴装备')),
      );
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('穿戴失败：$error')),
      );
    }
  }

  Future<void> _enhance(BuildContext context, WidgetRef ref) async {
    try {
      final result =
          await ref.read(playerSaveProvider.notifier).enhanceEquipment(
                database: database,
                instanceId: item.equipment.instanceId,
              );
      if (!context.mounted) {
        return;
      }
      if (!result.accepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_enhancementFailureMessage(result.reason))),
        );
        return;
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enhanced to +${result.newLevel}')),
      );
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('强化失败：$error')),
      );
    }
  }

  Future<void> _toggleLock(BuildContext context, WidgetRef ref) async {
    try {
      final controller = ref.read(playerSaveProvider.notifier);
      if (item.isLocked) {
        await controller.unlockEquipment(item.equipment.instanceId);
      } else {
        await controller.lockEquipment(item.equipment.instanceId);
      }
      if (!context.mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(item.isLocked ? '已解锁装备' : '已锁定装备')),
      );
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('锁定操作失败：$error')),
      );
    }
  }

  Future<void> _salvage(BuildContext context, WidgetRef ref) async {
    try {
      final result = await ref
          .read(playerSaveProvider.notifier)
          .salvageEquipment(item.equipment.instanceId);
      if (!context.mounted) {
        return;
      }
      if (!result.accepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_salvageFailureMessage(result.reason))),
        );
        return;
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('分解成功，获得 ${_materialsText(result.gainedMaterials)}'),
        ),
      );
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('分解失败：$error')),
      );
    }
  }
}

class _EnhancementSection extends StatelessWidget {
  const _EnhancementSection({
    required this.item,
    required this.database,
  });

  final EquipmentPageItemViewModel item;
  final GameDatabase database;

  @override
  Widget build(BuildContext context) {
    final service = const EquipmentEnhancementService();
    try {
      final config = service.requireConfig(database);
      final level = item.equipment.enhanceLevel;
      final cost =
          level >= config.maxLevel ? null : config.costForNextLevel(level);
      return _DetailSection(
        title: 'Enhancement',
        children: [
          Text('Enhance Level: +$level'),
          if (cost == null)
            const Text('Max Enhance Level')
          else
            Text(
              'Next Cost: gold x${cost.gold}, salvage_dust x${cost.dust}',
            ),
        ],
      );
    } on Object catch (error) {
      return _DetailSection(
        title: 'Enhancement',
        children: [Text('Enhancement config unavailable: $error')],
      );
    }
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        ...children,
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised.withValues(alpha: 0.18),
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

class _StatWrap extends StatelessWidget {
  const _StatWrap({required this.stats});

  final List<EquipmentStatViewModel> stats;

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return Text('无基础属性', style: Theme.of(context).textTheme.bodySmall);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final stat in stats)
          _Chip(
            label: '${stat.label} +${_formatNumber(stat.value)}',
            color: AppTheme.surfaceRaised,
          ),
      ],
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({
    required this.matchedTags,
    required this.rejectedTags,
  });

  final List<String> matchedTags;
  final List<String> rejectedTags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (matchedTags.isEmpty && rejectedTags.isEmpty)
          const _Chip(label: '暂无 BD 标签', color: AppTheme.surfaceRaised),
        for (final tag in matchedTags.take(4))
          _Chip(label: '推荐 $tag', color: AppTheme.primary),
        for (final tag in rejectedTags.take(3))
          _Chip(label: '警告 $tag', color: AppTheme.danger),
      ],
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    return _Chip(
      label: 'BD ${score.toStringAsFixed(1)}',
      color: AppTheme.primary,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(label, style: Theme.of(context).textTheme.bodySmall),
      ),
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

class _DebugGenerateButton extends StatelessWidget {
  const _DebugGenerateButton({
    required this.isGenerating,
    required this.onPressed,
  });

  final bool isGenerating;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: isGenerating
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.add_circle_outline),
      label: Text(isGenerating ? '生成中...' : '生成测试装备到背包'),
    );
  }
}

class _EquipmentMessage extends StatelessWidget {
  const _EquipmentMessage({
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

String _salvageFailureMessage(EquipmentInventoryActionReason reason) {
  switch (reason) {
    case EquipmentInventoryActionReason.locked:
      return '已锁定装备不能分解';
    case EquipmentInventoryActionReason.equipped:
      return '已穿戴装备不能分解';
    case EquipmentInventoryActionReason.notFound:
      return '装备不存在，无法分解';
    case EquipmentInventoryActionReason.salvaged:
      return '分解失败';
  }
}

String _enhancementFailureMessage(EquipmentEnhancementReason reason) {
  switch (reason) {
    case EquipmentEnhancementReason.equipmentNotFound:
      return '装备不存在，无法强化';
    case EquipmentEnhancementReason.maxLevelReached:
      return '装备已达到最大强化等级';
    case EquipmentEnhancementReason.insufficientDust:
      return 'salvage_dust 不足，无法强化';
    case EquipmentEnhancementReason.insufficientGold:
      return 'gold 不足，无法强化';
    case EquipmentEnhancementReason.invalidConfig:
      return '强化配置异常';
    case EquipmentEnhancementReason.enhanced:
      return '强化失败';
  }
}

String _materialsText(List<MaterialStack> materials) {
  if (materials.isEmpty) {
    return '无材料';
  }

  return materials
      .map((material) => '${material.materialId} x${material.quantity}')
      .join(', ');
}

String _affixLine(EquipmentAffixViewModel affix) {
  final roll =
      affix.rollValue == null ? '' : ' (${_formatNumber(affix.rollValue!)})';
  final mechanic = affix.isMechanic ? ' / 机制' : '';
  return '${affix.name}$roll$mechanic';
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(2);
}

String _signed(double value) {
  final sign = value >= 0 ? '+' : '';
  return '$sign${_formatNumber(value)}';
}

String _tags(List<String> tags) {
  return tags.isEmpty ? 'none' : tags.join(', ');
}
