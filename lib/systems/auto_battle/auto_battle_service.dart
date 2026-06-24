import '../../models/auto_battle_run_state.dart';
import '../../models/auto_salvage_config.dart';
import '../../models/battle_settlement_report.dart';
import '../../models/battle_state.dart';
import '../../models/inventory_state.dart';
import '../../models/save_data.dart';
import '../battle/battle_readiness_service.dart';
import '../battle/battle_settlement_service.dart';
import '../battle/battle_simulator.dart';
import '../chapters/chapter_service.dart';
import '../character/character_service.dart';
import '../character/class_service.dart';
import '../config/game_database.dart';
import '../inventory/auto_salvage_service.dart';
import '../monsters/monster_factory.dart';
import '../monsters/monster_service.dart';
import '../skills/skill_service.dart';
import '../stats/character_final_stats_service.dart';

typedef SaveDataWriter = Future<void> Function(SaveData saveData);

class AutoBattleService {
  const AutoBattleService({
    BattleSimulator simulator = const BattleSimulator(),
    BattleSettlementService settlementService = const BattleSettlementService(),
    MonsterFactory monsterFactory = const MonsterFactory(),
    AutoSalvageService autoSalvageService = const AutoSalvageService(),
    BattleReadinessService readinessService = const BattleReadinessService(),
    DateTime Function()? now,
  })  : _simulator = simulator,
        _settlementService = settlementService,
        _monsterFactory = monsterFactory,
        _autoSalvageService = autoSalvageService,
        _readinessService = readinessService,
        _now = now;

  final BattleSimulator _simulator;
  final BattleSettlementService _settlementService;
  final MonsterFactory _monsterFactory;
  final AutoSalvageService _autoSalvageService;
  final BattleReadinessService _readinessService;
  final DateTime Function()? _now;

  AutoBattleRunState startRun(SaveData saveData) {
    return AutoBattleRunState(
      saveData: saveData,
      isRunning: true,
      startedAt: (_now ?? DateTime.now)().toUtc(),
    );
  }

  AutoBattleRunState stopRun(AutoBattleRunState state) {
    return state.copyWith(
      isRunning: false,
      stopReason: AutoBattleStopReason.manualStop,
    );
  }

  Future<AutoBattleRunState> runOneBattle({
    required SaveData saveData,
    required GameDatabase database,
    required SaveDataWriter save,
    int seed = 1,
  }) async {
    final initial = startRun(saveData);
    final state = await _runOneBattleFromState(
      state: initial,
      database: database,
      save: save,
      seed: seed,
    );

    if (state.stopReason == AutoBattleStopReason.none) {
      return state.copyWith(
        isRunning: false,
        stopReason: AutoBattleStopReason.maxBattlesReached,
      );
    }

    return state.copyWith(isRunning: false);
  }

  Future<AutoBattleRunState> runManyBattles({
    required SaveData saveData,
    required GameDatabase database,
    required int maxBattles,
    required SaveDataWriter save,
    int seed = 1,
  }) async {
    var state = startRun(saveData);
    if (maxBattles <= 0) {
      return state.copyWith(
        isRunning: false,
        stopReason: AutoBattleStopReason.maxBattlesReached,
      );
    }

    for (var i = 0; i < maxBattles; i += 1) {
      state = await _runOneBattleFromState(
        state: state,
        database: database,
        save: save,
        seed: seed + i,
      );

      if (state.stopReason != AutoBattleStopReason.none) {
        return state.copyWith(isRunning: false);
      }
    }

    return state.copyWith(
      isRunning: false,
      stopReason: AutoBattleStopReason.maxBattlesReached,
    );
  }

  Future<AutoBattleRunState> _runOneBattleFromState({
    required AutoBattleRunState state,
    required GameDatabase database,
    required SaveDataWriter save,
    required int seed,
  }) async {
    final chapterService = ChapterService(database);
    final progress = state.saveData.playerProgress;
    final progressionStage = chapterService.currentProgressionStage(progress);
    final shouldFarmForLevel = chapterService.shouldFarmPreviousStage(progress);
    var farmingBecauseBattleFailed = false;
    var farmingBecauseUnsafe = false;
    var stage = shouldFarmForLevel
        ? chapterService.highestFarmableStage(progress)
        : progressionStage;
    if (stage == null) {
      return state.copyWith(
        isRunning: false,
        stopReason: AutoBattleStopReason.levelTooLow,
        progressionStageId: progressionStage.stageId,
        clearFarmingStageId: true,
        farmingBecauseLevelTooLow: false,
      );
    }
    if (!chapterService.canEnterStage(progress: progress, stage: stage)) {
      return state.copyWith(
        isRunning: false,
        stopReason: AutoBattleStopReason.levelTooLow,
        progressionStageId: progressionStage.stageId,
        clearFarmingStageId: true,
        farmingBecauseLevelTooLow: false,
      );
    }
    if (stage.monsterIds.isEmpty) {
      return state.copyWith(
        isRunning: false,
        stopReason: AutoBattleStopReason.battleFailed,
        progressionStageId: progressionStage.stageId,
        clearFarmingStageId: true,
        farmingBecauseLevelTooLow: false,
      );
    }

    final monsterService = MonsterService(database);
    var monsterConfig = monsterService.requireMonster(stage.monsterIds.first);
    if (!shouldFarmForLevel && stage.stageId == progressionStage.stageId) {
      final readiness = _evaluateReadiness(
        saveData: state.saveData,
        database: database,
        monsterId: monsterConfig.id,
      );
      final fallbackStage = chapterService.highestFarmableStage(progress);
      if (!readiness.safeToAttempt &&
          fallbackStage != null &&
          fallbackStage.stageId != stage.stageId) {
        stage = fallbackStage;
        farmingBecauseUnsafe = true;
        monsterConfig = monsterService.requireMonster(stage.monsterIds.first);
      }
    }
    var battle = _createBattle(
      saveData: state.saveData,
      database: database,
      monsterId: monsterConfig.id,
    );

    battle = _finishBattle(battle);

    if (!battle.isFinished) {
      return state.copyWith(
        isRunning: false,
        lastBattleLogs: battle.logs,
        stopReason: AutoBattleStopReason.battleNotFinished,
      );
    }
    if (battle.result != BattleResult.victory) {
      final fallbackStage = shouldFarmForLevel
          ? null
          : chapterService.highestFarmableStage(progress);
      if (fallbackStage == null || fallbackStage.stageId == stage.stageId) {
        return state.copyWith(
          isRunning: false,
          lastBattleLogs: battle.logs,
          stopReason: AutoBattleStopReason.battleFailed,
        );
      }

      stage = fallbackStage;
      farmingBecauseBattleFailed = true;
      monsterConfig = monsterService.requireMonster(stage.monsterIds.first);
      battle = _finishBattle(
        _createBattle(
          saveData: state.saveData,
          database: database,
          monsterId: monsterConfig.id,
        ),
      );

      if (!battle.isFinished) {
        return state.copyWith(
          isRunning: false,
          lastBattleLogs: battle.logs,
          stopReason: AutoBattleStopReason.battleNotFinished,
        );
      }
      if (battle.result != BattleResult.victory) {
        return state.copyWith(
          isRunning: false,
          lastBattleLogs: battle.logs,
          stopReason: AutoBattleStopReason.battleFailed,
        );
      }
    }

    final settlement = _settlementService.settle(
      battle: battle,
      monster: monsterConfig,
      saveData: state.saveData,
      database: database,
      seed: seed,
    );
    if (!settlement.accepted) {
      return state.copyWith(
        isRunning: false,
        lastBattleLogs: battle.logs,
        lastSettlementReport: settlement,
        stopReason: AutoBattleStopReason.battleFailed,
      );
    }

    final didFarm = shouldFarmForLevel ||
        farmingBecauseBattleFailed ||
        farmingBecauseUnsafe;
    var nextSave = didFarm
        ? settlement.saveData
        : chapterService.markStageCleared(settlement.saveData);
    final autoSalvageReport = _runAutoSalvageIfEnabled(
      saveData: nextSave,
      database: database,
    );
    if (autoSalvageReport != null) {
      nextSave = nextSave.copyWith(
        inventory: _inventorySaveFromState(
          autoSalvageReport.state,
          autoSalvageConfig: nextSave.inventory.autoSalvageConfig,
        ),
      );
    }
    final finalReport = _copyReportWithSaveData(settlement, nextSave);
    await save(nextSave);

    final nextProgressionStage =
        chapterService.maybeNextProgressionStage(progress);
    final stopReason = !didFarm && nextProgressionStage == null
        ? AutoBattleStopReason.chapterComplete
        : AutoBattleStopReason.none;

    return state
        .addSettlement(
          report: finalReport,
          logs: battle.logs,
          saveData: nextSave,
          farmingStageId: didFarm ? stage.stageId : null,
          farmingBecauseLevelTooLow: shouldFarmForLevel,
          farmingBecauseBattleFailed: farmingBecauseBattleFailed,
          farmingBecauseUnsafe: farmingBecauseUnsafe,
          progressionStageId: progressionStage.stageId,
          autoSalvagedCount: autoSalvageReport?.salvagedCount ?? 0,
          autoSalvageGainedMaterials:
              autoSalvageReport?.gainedMaterials ?? const [],
        )
        .copyWith(
          isRunning: stopReason == AutoBattleStopReason.none,
          stopReason: stopReason,
        );
  }

  BattleReadinessReport _evaluateReadiness({
    required SaveData saveData,
    required GameDatabase database,
    required String monsterId,
  }) {
    final character = CharacterService(
      classService: ClassService(database),
    ).restoreFromSave(saveData);
    final inventory = _inventoryStateFromSave(saveData.inventory);
    final computedStats = const CharacterFinalStatsService().compute(
      character: character,
      loadout: inventory.equipmentLoadout,
      inventory: inventory,
      database: database,
    );
    final monster = _monsterFactory.create(
      config: MonsterService(database).requireMonster(monsterId),
    );

    return _readinessService.evaluate(
      characterStats: computedStats.computedStats,
      monster: monster,
    );
  }

  BattleState _finishBattle(BattleState battle) {
    var state = battle;
    for (var i = 0; i < 100 && !state.isFinished; i += 1) {
      state = _simulator.tick(state, 1);
    }

    return state;
  }

  BattleState _createBattle({
    required SaveData saveData,
    required GameDatabase database,
    required String monsterId,
  }) {
    final character = CharacterService(
      classService: ClassService(database),
    ).restoreFromSave(saveData);
    final inventory = _inventoryStateFromSave(saveData.inventory);
    final computedStats = const CharacterFinalStatsService().compute(
      character: character,
      loadout: inventory.equipmentLoadout,
      inventory: inventory,
      database: database,
    );
    final monster = _monsterFactory.create(
      config: MonsterService(database).requireMonster(monsterId),
    );

    return _simulator.createBattle(
      character: character,
      computedStats: computedStats.computedStats,
      skillLoadout: saveData.playerProgress.skillLoadout,
      monster: monster,
      skillService: SkillService(database),
    );
  }

  BattleSettlementReport _copyReportWithSaveData(
    BattleSettlementReport report,
    SaveData saveData,
  ) {
    return BattleSettlementReport(
      accepted: report.accepted,
      reason: report.reason,
      saveData: saveData,
      gainedExperience: report.gainedExperience,
      gainedGold: report.gainedGold,
      gainedMaterials: report.gainedMaterials,
      generatedEquipment: report.generatedEquipment,
      rejectedEquipment: report.rejectedEquipment,
      leveledUp: report.leveledUp,
      newLevel: report.newLevel,
    );
  }

  AutoSalvageReport? _runAutoSalvageIfEnabled({
    required SaveData saveData,
    required GameDatabase database,
  }) {
    final config = saveData.inventory.autoSalvageConfig;
    if (!config.enabled) {
      return null;
    }

    return _autoSalvageService.processInventory(
      inventory: _inventoryStateFromSave(saveData.inventory),
      database: database,
      classId: saveData.playerProgress.currentClassId,
      config: config,
    );
  }
}

InventoryState _inventoryStateFromSave(InventorySave save) {
  return InventoryState(
    equipmentInstanceIds: save.equipmentInstanceIds,
    equipmentInstances: save.equipmentInstances,
    equipmentLoadout: save.equipmentLoadout,
    equipmentCapacity: save.equipmentCapacity,
    materials: save.materials,
    lockedEquipmentInstanceIds: save.lockedEquipmentInstanceIds,
  );
}

InventorySave _inventorySaveFromState(
  InventoryState state, {
  required AutoSalvageConfig autoSalvageConfig,
}) {
  return InventorySave(
    equipmentInstanceIds: state.equipmentInstanceIds,
    equipmentInstances: state.equipmentInstances,
    equipmentLoadout: state.equipmentLoadout,
    equipmentCapacity: state.equipmentCapacity,
    materials: state.materials,
    lockedEquipmentInstanceIds: state.lockedEquipmentInstanceIds,
    autoSalvageConfig: autoSalvageConfig,
  );
}
