import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/save/player_save_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/battle_settlement_report.dart';
import '../../models/battle_state.dart';
import '../../models/save_data.dart';
import '../../systems/config/game_database.dart';
import '../../systems/config/game_database_service.dart';
import 'battle_controller.dart';

class BattlePage extends ConsumerStatefulWidget {
  const BattlePage({super.key});

  @override
  ConsumerState<BattlePage> createState() => _BattlePageState();
}

class _BattlePageState extends ConsumerState<BattlePage> {
  late final BattleController _controller;
  bool _isSettling = false;

  @override
  void initState() {
    super.initState();
    _controller = BattleController();
  }

  @override
  Widget build(BuildContext context) {
    final saveLoad = ref.watch(playerSaveProvider);
    final databaseLoad = ref.watch(gameDatabaseLoadProvider);

    if (saveLoad.isLoading && !saveLoad.hasValue) {
      return const _BattleMessage(
        title: 'Loading save',
        message: 'Creating or loading the current character save.',
        icon: Icons.hourglass_empty,
      );
    }

    if (saveLoad.hasError && !saveLoad.hasValue) {
      return _BattleMessage(
        title: 'Save load failed',
        message: saveLoad.error.toString(),
        icon: Icons.error_outline,
      );
    }

    final saveData = saveLoad.valueOrNull;
    if (saveData == null) {
      return const _BattleMessage(
        title: 'Preparing save',
        message: 'Battle will be available after the save is ready.',
        icon: Icons.hourglass_empty,
      );
    }

    return databaseLoad.when(
      data: (result) {
        return _BattlePageContent(
          controller: _controller,
          saveData: saveData,
          isSettling: _isSettling,
          onStart: () => _startBattle(saveData, result.database),
          onTick: () => _tick(saveData, result.database),
          onAutoFinish: () => _autoFinish(saveData, result.database),
          onSettle: () => _settleIfVictory(saveData, result.database),
        );
      },
      error: (error, _) {
        return _BattleMessage(
          title: 'Battle data load failed',
          message: error.toString(),
          icon: Icons.error_outline,
        );
      },
      loading: () {
        return const _BattleMessage(
          title: 'Loading battle data',
          message: 'Skills, monsters, and loot tables are loading.',
          icon: Icons.hourglass_empty,
        );
      },
    );
  }

  void _startBattle(SaveData saveData, GameDatabase database) {
    setState(() {
      _controller.createBattle(saveData: saveData, database: database);
    });
  }

  Future<void> _tick(SaveData saveData, GameDatabase database) async {
    setState(() {
      _controller.tick();
    });
    await _settleIfVictory(saveData, database);
  }

  Future<void> _autoFinish(SaveData saveData, GameDatabase database) async {
    setState(() {
      _controller.autoAdvance();
    });
    await _settleIfVictory(saveData, database);
  }

  Future<void> _settleIfVictory(
      SaveData saveData, GameDatabase database) async {
    if (!_controller.canSettle || _controller.hasSettled || _isSettling) {
      return;
    }

    setState(() {
      _isSettling = true;
    });
    try {
      await _controller.settleVictory(
        saveData: saveData,
        database: database,
        saveController: ref.read(playerSaveProvider.notifier),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSettling = false;
        });
      }
    }
  }
}

class _BattlePageContent extends StatelessWidget {
  const _BattlePageContent({
    required this.controller,
    required this.saveData,
    required this.isSettling,
    required this.onStart,
    required this.onTick,
    required this.onAutoFinish,
    required this.onSettle,
  });

  final BattleController controller;
  final SaveData saveData;
  final bool isSettling;
  final VoidCallback onStart;
  final VoidCallback onTick;
  final VoidCallback onAutoFinish;
  final VoidCallback onSettle;

  @override
  Widget build(BuildContext context) {
    final battle = controller.battle;
    final report = controller.settlementReport;
    final monsterName = controller.monsterConfig?.name ?? 'skeleton_grunt';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Battle', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        _Section(
          title: 'Encounter',
          children: [
            _InfoRow(
                label: 'Character',
                value: saveData.playerProgress.currentClassId),
            _InfoRow(label: 'Monster', value: monsterName),
            _InfoRow(
                label: 'Status', value: battle?.result.name ?? 'not_started'),
            _InfoRow(
                label: 'Elapsed',
                value: _formatNumber(battle?.elapsedSeconds ?? 0)),
            if (battle != null)
              _InfoRow(
                label: 'HP',
                value:
                    '${_formatNumber(battle.monster.currentHp)} / ${_formatNumber(battle.monster.maxHp)}',
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: onStart,
              child: const Text('Start Battle'),
            ),
            FilledButton.tonal(
              onPressed: battle == null || battle.isFinished ? null : onTick,
              child: const Text('Tick 1s'),
            ),
            FilledButton.tonal(
              onPressed:
                  battle == null || battle.isFinished ? null : onAutoFinish,
              child: const Text('Auto Finish'),
            ),
            if (battle?.result == BattleResult.victory)
              OutlinedButton(
                onPressed:
                    controller.hasSettled || isSettling ? null : onSettle,
                child: Text(isSettling ? 'Settling...' : 'Settle Victory'),
              ),
          ],
        ),
        if (controller.errorMessage != null) ...[
          const SizedBox(height: 12),
          _WarningBanner(message: controller.errorMessage!),
        ],
        const SizedBox(height: 16),
        _Section(
          title: 'Recent Logs',
          children: [
            if (battle == null)
              const Text('No battle started yet.')
            else
              for (final log in battle.logs
                  .skip(battle.logs.length > 20 ? battle.logs.length - 20 : 0))
                Text(
                  '[${_formatNumber(log.time)}s] ${log.message}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
          ],
        ),
        if (report != null) ...[
          const SizedBox(height: 16),
          _SettlementReportView(report: report),
        ],
      ],
    );
  }
}

class _SettlementReportView extends StatelessWidget {
  const _SettlementReportView({required this.report});

  final BattleSettlementReport report;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Settlement',
      children: [
        _InfoRow(label: 'Accepted', value: report.accepted.toString()),
        _InfoRow(
            label: 'Experience', value: report.gainedExperience.toString()),
        _InfoRow(label: 'Gold', value: report.gainedGold.toString()),
        _InfoRow(
          label: 'Materials',
          value: report.gainedMaterials
              .fold<int>(
                0,
                (total, stack) => total + stack.quantity,
              )
              .toString(),
        ),
        _InfoRow(
          label: 'Dropped equipment',
          value: report.generatedEquipment.length.toString(),
        ),
        _InfoRow(
          label: 'Rejected equipment',
          value: report.rejectedEquipment.length.toString(),
        ),
        _InfoRow(label: 'Leveled up', value: report.leveledUp.toString()),
        _InfoRow(label: 'New level', value: report.newLevel.toString()),
      ],
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

class _BattleMessage extends StatelessWidget {
  const _BattleMessage({
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

  return value.toStringAsFixed(1);
}
