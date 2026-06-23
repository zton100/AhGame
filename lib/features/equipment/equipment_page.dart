import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/inventory_state.dart';
import '../../systems/config/game_database_service.dart';
import 'equipment_card_view_model.dart';
import 'equipment_page_view_model.dart';

final equipmentInventoryProvider = StateProvider<InventoryState>((ref) {
  return const InventoryState(equipmentInstanceIds: []);
});

class EquipmentPage extends ConsumerWidget {
  const EquipmentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final databaseLoad = ref.watch(gameDatabaseLoadProvider);
    final inventory = ref.watch(equipmentInventoryProvider);

    return databaseLoad.when(
      data: (result) {
        final viewModel = const EquipmentPageViewModelFactory().create(
          inventory: inventory,
          database: result.database,
        );
        return _EquipmentPageContent(viewModel: viewModel);
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
}

class _EquipmentPageContent extends StatelessWidget {
  const _EquipmentPageContent({required this.viewModel});

  final EquipmentPageViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.isEmpty) {
      return const _EquipmentMessage(
        title: '背包暂无装备',
        message: '击败敌人后获得的装备会出现在这里。',
        icon: Icons.inventory_2_outlined,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('装备', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          '背包 ${viewModel.items.length} 件装备',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (viewModel.missingInstanceIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          _WarningBanner(
            message: '有 ${viewModel.missingInstanceIds.length} 件装备缺少完整实例数据。',
          ),
        ],
        const SizedBox(height: 12),
        for (final item in viewModel.items) ...[
          _EquipmentCard(item: item),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  const _EquipmentCard({required this.item});

  final EquipmentPageItemViewModel item;

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
                          card.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: qualityColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${card.qualityLabel} · ${item.slotLabel}',
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
      builder: (context) => _EquipmentDetailDialog(item: item),
    );
  }
}

class _EquipmentDetailDialog extends StatelessWidget {
  const _EquipmentDetailDialog({required this.item});

  final EquipmentPageItemViewModel item;

  @override
  Widget build(BuildContext context) {
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
            Text('${card.qualityLabel} · ${item.slotLabel}'),
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
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
          const _Chip(label: '暂无BD标签', color: AppTheme.surfaceRaised),
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

String _affixLine(EquipmentAffixViewModel affix) {
  final roll =
      affix.rollValue == null ? '' : ' (${_formatNumber(affix.rollValue!)})';
  final mechanic = affix.isMechanic ? ' · 机制' : '';
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
