import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/save/player_save_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/auto_battle_run_state.dart';
import '../../models/battle_settlement_report.dart';
import '../../models/battle_state.dart';
import '../../models/save_data.dart';
import '../../systems/auto_battle/auto_battle_service.dart';
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
  late final AutoBattleService _autoBattleService;
  AutoBattleRunState? _autoRunState;
  bool _isSettling = false;

  @override
  void initState() {
    super.initState();
    _controller = BattleController();
    _autoBattleService = const AutoBattleService();
  }

  @override
  Widget build(BuildContext context) {
    final saveLoad = ref.watch(playerSaveProvider);
    final databaseLoad = ref.watch(gameDatabaseLoadProvider);

    if (saveLoad.isLoading && !saveLoad.hasValue) {
      return const _BattleMessage(
        title: '正在读取存档',
        message: '正在创建或读取当前角色存档。',
        icon: Icons.hourglass_empty,
      );
    }

    if (saveLoad.hasError && !saveLoad.hasValue) {
      return _BattleMessage(
        title: '存档读取失败',
        message: saveLoad.error.toString(),
        icon: Icons.error_outline,
      );
    }

    final saveData = saveLoad.valueOrNull;
    if (saveData == null) {
      return const _BattleMessage(
        title: '正在准备存档',
        message: '存档准备完成后即可开始战斗。',
        icon: Icons.hourglass_empty,
      );
    }

    return databaseLoad.when(
      data: (result) {
        return _BattlePageContent(
          controller: _controller,
          saveData: saveData,
          progress: _controller.progressFor(
            saveData: saveData,
            database: result.database,
          ),
          autoRunState: _autoRunState,
          isSettling: _isSettling,
          onRunOneBattle: () => _runAutoBattles(
            saveData: saveData,
            database: result.database,
            maxBattles: 1,
          ),
          onRunTenBattles: () => _runAutoBattles(
            saveData: saveData,
            database: result.database,
            maxBattles: 10,
          ),
          onStopAutoBattle: () => _stopAutoBattle(saveData),
          onStart: () => _startBattle(saveData, result.database),
          onTick: () => _tick(saveData, result.database),
          onAutoFinish: () => _autoFinish(saveData, result.database),
          onSettle: () => _settleIfVictory(saveData, result.database),
        );
      },
      error: (error, _) {
        return _BattleMessage(
          title: '战斗数据加载失败',
          message: error.toString(),
          icon: Icons.error_outline,
        );
      },
      loading: () {
        return const _BattleMessage(
          title: '正在加载战斗数据',
          message: '技能、怪物和掉落表加载中。',
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

  Future<void> _runAutoBattles({
    required SaveData saveData,
    required GameDatabase database,
    required int maxBattles,
  }) async {
    setState(() {
      _autoRunState = _autoBattleService.startRun(saveData);
    });

    final runState = await _autoBattleService.runManyBattles(
      saveData: saveData,
      database: database,
      maxBattles: maxBattles,
      save: ref.read(playerSaveProvider.notifier).save,
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _autoRunState = runState;
    });
  }

  void _stopAutoBattle(SaveData saveData) {
    setState(() {
      _autoRunState = _autoBattleService.stopRun(
        _autoRunState ?? AutoBattleRunState.initial(saveData),
      );
    });
  }
}

class _BattlePageContent extends StatelessWidget {
  const _BattlePageContent({
    required this.controller,
    required this.saveData,
    required this.progress,
    required this.autoRunState,
    required this.isSettling,
    required this.onRunOneBattle,
    required this.onRunTenBattles,
    required this.onStopAutoBattle,
    required this.onStart,
    required this.onTick,
    required this.onAutoFinish,
    required this.onSettle,
  });

  final BattleController controller;
  final SaveData saveData;
  final ChapterBattleProgress progress;
  final AutoBattleRunState? autoRunState;
  final bool isSettling;
  final VoidCallback onRunOneBattle;
  final VoidCallback onRunTenBattles;
  final VoidCallback onStopAutoBattle;
  final VoidCallback onStart;
  final VoidCallback onTick;
  final VoidCallback onAutoFinish;
  final VoidCallback onSettle;

  @override
  Widget build(BuildContext context) {
    final battle = controller.battle;
    final report = controller.settlementReport;
    final monsterName = controller.monsterConfig?.name ?? progress.monsterId;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('战斗', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        _Section(
          title: '连续战斗',
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: onRunOneBattle,
                  child: const Text('运行 1 场'),
                ),
                FilledButton(
                  onPressed: onRunTenBattles,
                  child: const Text('运行 10 场'),
                ),
                OutlinedButton(
                  onPressed: onStopAutoBattle,
                  child: const Text('停止连续战斗'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _AutoBattleSummary(runState: autoRunState),
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          title: '遭遇',
          children: [
            _InfoRow(
                label: '角色', value: saveData.playerProgress.currentClassId),
            _InfoRow(label: '章节', value: progress.chapterName),
            _InfoRow(
              label: '关卡',
              value: '${progress.stageId} ${progress.stageName}',
            ),
            _InfoRow(label: 'Boss 关', value: _yesNo(progress.isBossStage)),
            _InfoRow(label: '怪物', value: monsterName),
            _InfoRow(label: '状态', value: _battleResultLabel(battle?.result)),
            _InfoRow(
                label: '耗时', value: _formatNumber(battle?.elapsedSeconds ?? 0)),
            if (battle != null)
              _InfoRow(
                label: '怪物生命',
                value:
                    '${_formatNumber(battle.monster.currentHp)} / ${_formatNumber(battle.monster.maxHp)}',
              ),
            if (battle != null)
              _InfoRow(
                label: '玩家生命',
                value:
                    '${_formatNumber(battle.playerCurrentHp)} / ${_formatNumber(battle.playerMaxHp)}',
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
              child: const Text('开始战斗'),
            ),
            FilledButton.tonal(
              onPressed: battle == null || battle.isFinished ? null : onTick,
              child: const Text('推进 1 秒'),
            ),
            FilledButton.tonal(
              onPressed:
                  battle == null || battle.isFinished ? null : onAutoFinish,
              child: const Text('自动打完'),
            ),
            if (battle?.result == BattleResult.victory)
              OutlinedButton(
                onPressed:
                    controller.hasSettled || isSettling ? null : onSettle,
                child: Text(isSettling ? '结算中...' : '结算胜利'),
              ),
          ],
        ),
        if (controller.errorMessage != null) ...[
          const SizedBox(height: 12),
          _WarningBanner(message: controller.errorMessage!),
        ],
        if (battle?.result == BattleResult.defeat) ...[
          const SizedBox(height: 12),
          const _WarningBanner(
            message: '战斗失败。请强化装备、调整装备，或重复刷已通关关卡提升实力。',
          ),
        ],
        if (controller.advancedAfterSettlement) ...[
          const SizedBox(height: 12),
          const _SuccessBanner(message: '已推进到下一关。'),
        ],
        const SizedBox(height: 16),
        _Section(
          title: '最近日志',
          children: [
            if (battle == null)
              const Text('尚未开始战斗。')
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

class _AutoBattleSummary extends StatelessWidget {
  const _AutoBattleSummary({required this.runState});

  final AutoBattleRunState? runState;

  @override
  Widget build(BuildContext context) {
    final state = runState;
    if (state == null) {
      return const Text('尚未运行连续战斗。');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AutoBattleExplanation(state: state),
        const SizedBox(height: 12),
        _InfoRow(
          label: '完成场次',
          value: state.battlesCompleted.toString(),
        ),
        _InfoRow(label: '推进模式', value: _progressModeLabel(state)),
        _InfoRow(label: '总经验', value: state.totalExperience.toString()),
        _InfoRow(label: '总金币', value: state.totalGold.toString()),
        _InfoRow(
          label: '获得材料',
          value: state.totalMaterials.values
              .fold<int>(0, (total, quantity) => total + quantity)
              .toString(),
        ),
        _InfoRow(
          label: '掉落装备',
          value: state.generatedEquipmentCount.toString(),
        ),
        _InfoRow(
          label: '拒收装备',
          value: state.rejectedEquipmentCount.toString(),
        ),
        _InfoRow(
          label: '自动分解装备',
          value: state.autoSalvagedEquipmentCount.toString(),
        ),
        _InfoRow(
          label: '自动分解材料',
          value: state.autoSalvageMaterials.values
              .fold<int>(0, (total, quantity) => total + quantity)
              .toString(),
        ),
        _InfoRow(label: '停止原因', value: _stopReasonLabel(state.stopReason)),
        if (state.lastSettlementReport != null) ...[
          _InfoRow(
            label: '上场经验',
            value: state.lastSettlementReport!.gainedExperience.toString(),
          ),
          _InfoRow(
            label: '上场掉落',
            value: state.lastSettlementReport!.generatedEquipment.length
                .toString(),
          ),
          _InfoRow(
            label: '上场拒收',
            value:
                state.lastSettlementReport!.rejectedEquipment.length.toString(),
          ),
        ],
        _InfoRow(
          label: '推进关卡',
          value: state.progressionStageId ?? '-',
        ),
        _InfoRow(
          label: '刷取关卡',
          value: state.farmingStageId ?? '-',
        ),
        _InfoRow(
          label: '因等级不足回刷',
          value: _yesNo(state.farmingBecauseLevelTooLow),
        ),
        _InfoRow(
          label: '因战斗失败回刷',
          value: _yesNo(state.farmingBecauseBattleFailed),
        ),
        _InfoRow(
          label: '因危险评估回刷',
          value: _yesNo(state.farmingBecauseUnsafe),
        ),
        if (state.farmingBecauseLevelTooLow)
          const _WarningBanner(
            message: '当前关卡等级要求过高，正在自动刷最高可进入的已通关关卡。',
          ),
        if (state.farmingBecauseBattleFailed)
          const _WarningBanner(
            message: '当前推进关卡战斗失败，正在自动刷最高可承受的已通关关卡。',
          ),
        if (state.farmingBecauseUnsafe)
          const _WarningBanner(
            message: '当前推进关卡风险较高，正在优先刷最高已通关关卡。',
          ),
        if (state.stopReason == AutoBattleStopReason.levelTooLow)
          const _WarningBanner(
            message: '当前关卡等级不足，请提升等级或等待重复刷关功能处理。',
          ),
        if (state.stopReason == AutoBattleStopReason.chapterComplete)
          const _SuccessBanner(message: '当前章节已完成。'),
        if (state.stopReason == AutoBattleStopReason.battleFailed)
          const _WarningBanner(
            message: '战斗失败。请强化装备、调整装备，或重复刷已通关关卡提升实力。',
          ),
        const SizedBox(height: 8),
        Text('最近连续战斗日志', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        if (state.lastBattleLogs.isEmpty)
          const Text('暂无连续战斗日志。')
        else
          for (final log in state.lastBattleLogs.skip(
            state.lastBattleLogs.length > 20
                ? state.lastBattleLogs.length - 20
                : 0,
          ))
            Text(
              '[${_formatNumber(log.time)}s] ${log.message}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
      ],
    );
  }
}

class _AutoBattleExplanation extends StatelessWidget {
  const _AutoBattleExplanation({required this.state});

  final AutoBattleRunState state;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: '自动战斗说明',
      children: [
        _InfoRow(
          label: '推进关卡',
          value: _stageLabel(
            state.lastProgressionStageId,
            state.lastProgressionStageName,
          ),
        ),
        _InfoRow(
          label: '实际关卡',
          value:
              _stageLabel(state.lastActualStageId, state.lastActualStageName),
        ),
        _InfoRow(label: '推进模式', value: _fallbackReasonLabel(state)),
        _InfoRow(
          label: '可行性原因',
          value: _readinessReasonLabel(state.lastReadinessReason),
        ),
        _InfoRow(
          label: '预计击杀时间',
          value:
              _optionalNumber(state.lastEstimatedSecondsToKill, suffix: ' 秒'),
        ),
        _InfoRow(
          label: '预计承伤',
          value: _optionalNumber(state.lastEstimatedIncomingDamage),
        ),
        _InfoRow(
          label: '玩家有效生命',
          value: _optionalNumber(state.lastPlayerEffectiveHp),
        ),
        _InfoRow(
          label: '玩家秒伤',
          value: _optionalNumber(state.lastPlayerDamagePerSecond),
        ),
        _InfoRow(
          label: '怪物单次伤害',
          value: _optionalNumber(state.lastMonsterDamagePerHit),
        ),
        _InfoRow(
          label: '下一步建议',
          value: _recommendedActionLabel(state.recommendedNextAction),
        ),
        Text(
          _recommendedActionDescription(state.recommendedNextAction),
          style: Theme.of(context).textTheme.bodySmall,
        ),
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
      title: '结算报告',
      children: [
        _InfoRow(label: '已结算', value: _yesNo(report.accepted)),
        _InfoRow(label: '经验', value: report.gainedExperience.toString()),
        _InfoRow(label: '金币', value: report.gainedGold.toString()),
        _InfoRow(
          label: '材料',
          value: report.gainedMaterials
              .fold<int>(
                0,
                (total, stack) => total + stack.quantity,
              )
              .toString(),
        ),
        _InfoRow(
          label: '掉落装备',
          value: report.generatedEquipment.length.toString(),
        ),
        _InfoRow(
          label: '拒收装备',
          value: report.rejectedEquipment.length.toString(),
        ),
        _InfoRow(label: '是否升级', value: _yesNo(report.leveledUp)),
        _InfoRow(label: '当前等级', value: report.newLevel.toString()),
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

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
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

String _progressModeLabel(AutoBattleRunState state) {
  if (state.farmingBecauseLevelTooLow) {
    return '等级不足回刷';
  }
  if (state.farmingBecauseUnsafe) {
    return '危险评估回刷';
  }
  if (state.farmingBecauseBattleFailed) {
    return '失败后回刷';
  }
  if (state.battlesCompleted > 0) {
    return '主线推进';
  }

  return '空闲';
}

String _stageLabel(String? stageId, String? stageName) {
  if (stageId == null) {
    return '-';
  }
  if (stageName == null || stageName.isEmpty) {
    return stageId;
  }
  return '$stageId $stageName';
}

String _optionalNumber(double? value, {String suffix = ''}) {
  if (value == null) {
    return '-';
  }
  return '${_formatNumber(value)}$suffix';
}

String _fallbackReasonLabel(AutoBattleRunState state) {
  switch (state.lastFallbackReason) {
    case AutoBattleFallbackReason.none:
      return state.battlesCompleted > 0 ? '正常推进' : '空闲';
    case AutoBattleFallbackReason.levelTooLow:
      return '因等级不足回刷';
    case AutoBattleFallbackReason.battleFailed:
      return '因战斗失败回刷';
    case AutoBattleFallbackReason.unsafeLowDamage:
      return '因伤害不足回刷';
    case AutoBattleFallbackReason.unsafeLowSurvivability:
      return '因生存不足回刷';
  }
}

String _readinessReasonLabel(AutoBattleReadinessReason reason) {
  switch (reason) {
    case AutoBattleReadinessReason.none:
      return '无';
    case AutoBattleReadinessReason.safe:
      return '安全';
    case AutoBattleReadinessReason.lowDamage:
      return '伤害不足';
    case AutoBattleReadinessReason.lowSurvivability:
      return '生存不足';
  }
}

String _recommendedActionLabel(AutoBattleRecommendedAction action) {
  switch (action) {
    case AutoBattleRecommendedAction.none:
      return '无需额外操作';
    case AutoBattleRecommendedAction.enhanceWeapon:
      return '强化武器';
    case AutoBattleRecommendedAction.enhanceArmorOrHp:
      return '强化护甲或生命装备';
    case AutoBattleRecommendedAction.farmForMaterials:
      return '刷旧关积累材料';
    case AutoBattleRecommendedAction.equipBetterGear:
      return '检查更合适装备';
    case AutoBattleRecommendedAction.continueProgression:
      return '继续推进';
  }
}

String _recommendedActionDescription(AutoBattleRecommendedAction action) {
  switch (action) {
    case AutoBattleRecommendedAction.none:
      return '不需要额外操作。';
    case AutoBattleRecommendedAction.enhanceWeapon:
      return '伤害不足，建议优先强化主武器或更换高攻击装备。';
    case AutoBattleRecommendedAction.enhanceArmorOrHp:
      return '生存不足，建议强化护甲/生命装备，或更换更高生存属性装备。';
    case AutoBattleRecommendedAction.farmForMaterials:
      return '当前推进受阻，正在刷旧关积累材料和装备。';
    case AutoBattleRecommendedAction.equipBetterGear:
      return '建议检查背包中是否有更适合当前职业的装备。';
    case AutoBattleRecommendedAction.continueProgression:
      return '当前战斗预估安全，可以继续推进。';
  }
}

String _yesNo(bool value) {
  return value ? '是' : '否';
}

String _battleResultLabel(BattleResult? result) {
  switch (result) {
    case BattleResult.running:
      return '进行中';
    case BattleResult.victory:
      return '胜利';
    case BattleResult.defeat:
      return '失败';
    case null:
      return '未开始';
  }
}

String _stopReasonLabel(AutoBattleStopReason reason) {
  switch (reason) {
    case AutoBattleStopReason.none:
      return '无';
    case AutoBattleStopReason.manualStop:
      return '手动停止';
    case AutoBattleStopReason.levelTooLow:
      return '等级不足';
    case AutoBattleStopReason.chapterComplete:
      return '章节完成';
    case AutoBattleStopReason.battleNotFinished:
      return '战斗未结束';
    case AutoBattleStopReason.battleFailed:
      return '战斗失败';
    case AutoBattleStopReason.inventoryFull:
      return '背包已满';
    case AutoBattleStopReason.maxBattlesReached:
      return '达到场次上限';
  }
}
