import '../../core/save/player_save_provider.dart';
import '../../models/battle_settlement_report.dart';
import '../../models/battle_state.dart';
import '../../models/chapter_config.dart';
import '../../models/monster_config.dart';
import '../../models/save_data.dart';
import '../../systems/battle/battle_settlement_service.dart';
import '../../systems/battle/battle_simulator.dart';
import '../../systems/chapters/chapter_service.dart';
import '../../systems/character/character_service.dart';
import '../../systems/character/class_service.dart';
import '../../systems/config/game_database.dart';
import '../../systems/monsters/monster_factory.dart';
import '../../systems/monsters/monster_service.dart';
import '../../systems/skills/skill_service.dart';
import '../../systems/stats/character_final_stats_service.dart';

class BattleController {
  BattleController({
    BattleSimulator simulator = const BattleSimulator(),
    BattleSettlementService settlementService = const BattleSettlementService(),
    MonsterFactory monsterFactory = const MonsterFactory(),
  })  : _simulator = simulator,
        _settlementService = settlementService,
        _monsterFactory = monsterFactory;

  final BattleSimulator _simulator;
  final BattleSettlementService _settlementService;
  final MonsterFactory _monsterFactory;

  BattleState? battle;
  ChapterConfig? chapterConfig;
  StageConfig? stageConfig;
  MonsterConfig? monsterConfig;
  BattleSettlementReport? settlementReport;
  String? errorMessage;
  bool advancedAfterSettlement = false;

  bool get canSettle => battle?.result == BattleResult.victory;
  bool get hasSettled => settlementReport?.accepted == true;

  void createBattle({
    required SaveData saveData,
    required GameDatabase database,
  }) {
    final character = CharacterService(
      classService: ClassService(database),
    ).restoreFromSave(saveData);
    final inventory = inventoryStateFromSave(saveData.inventory);
    final computedStats = const CharacterFinalStatsService().compute(
      character: character,
      loadout: inventory.equipmentLoadout,
      inventory: inventory,
      database: database,
    );
    final skillService = SkillService(database);
    final chapterService = ChapterService(database);
    final chapter = chapterService.requireChapter(
      saveData.playerProgress.currentChapterId,
    );
    final stage = chapterService.currentStage(saveData.playerProgress);
    if (!chapterService.canEnterStage(
      progress: saveData.playerProgress,
      stage: stage,
    )) {
      _clearBattleProgress(
        chapter: chapter,
        stage: stage,
        message: 'Required level ${stage.requiredLevel} for ${stage.stageId}.',
      );
      return;
    }
    if (stage.monsterIds.isEmpty) {
      _clearBattleProgress(
        chapter: chapter,
        stage: stage,
        message: 'Stage has no monsters: ${stage.stageId}',
      );
      return;
    }
    final monsterService = MonsterService(database);
    final config = monsterService.requireMonster(stage.monsterIds.first);
    final monster = _monsterFactory.create(config: config);

    chapterConfig = chapter;
    stageConfig = stage;
    monsterConfig = config;
    settlementReport = null;
    advancedAfterSettlement = false;
    errorMessage = null;
    battle = _simulator.createBattle(
      character: character,
      computedStats: computedStats.computedStats,
      skillLoadout: saveData.playerProgress.skillLoadout,
      skillLevels: saveData.playerProgress.skillLevels,
      monster: monster,
      skillService: skillService,
    );
  }

  void tick({double seconds = 1}) {
    final current = battle;
    if (current == null) {
      errorMessage = 'Start a battle before ticking.';
      return;
    }
    errorMessage = null;
    battle = _simulator.tick(current, seconds);
  }

  void autoAdvance({int maxTicks = 100, double secondsPerTick = 1}) {
    final current = battle;
    if (current == null) {
      errorMessage = 'Start a battle before auto advancing.';
      return;
    }

    var next = current;
    for (var i = 0; i < maxTicks && !next.isFinished; i += 1) {
      next = _simulator.tick(next, secondsPerTick);
    }
    errorMessage = null;
    battle = next;
  }

  Future<BattleSettlementReport?> settleVictory({
    required SaveData saveData,
    required GameDatabase database,
    required PlayerSaveController saveController,
    int seed = 1,
  }) async {
    if (settlementReport != null) {
      return settlementReport;
    }

    final current = battle;
    final config = monsterConfig;
    if (current == null || config == null) {
      errorMessage = 'Start a battle before settlement.';
      return null;
    }
    if (current.result != BattleResult.victory) {
      errorMessage = 'Only victory battles can be settled.';
      return null;
    }

    final report = _settlementService.settle(
      battle: current,
      monster: config,
      saveData: saveData,
      database: database,
      seed: seed,
    );
    final finalReport = report.accepted
        ? _copyReportWithSaveData(
            report,
            ChapterService(database).markStageCleared(report.saveData),
          )
        : report;
    settlementReport = finalReport;
    advancedAfterSettlement = finalReport.accepted;
    errorMessage = finalReport.accepted ? null : finalReport.reason.name;

    if (finalReport.accepted) {
      await saveController.save(finalReport.saveData);
    }

    return finalReport;
  }

  ChapterBattleProgress progressFor({
    required SaveData saveData,
    required GameDatabase database,
  }) {
    final chapterService = ChapterService(database);
    final chapter = chapterService.requireChapter(
      saveData.playerProgress.currentChapterId,
    );
    final stage = chapterService.currentStage(saveData.playerProgress);

    return ChapterBattleProgress(
      chapterName: chapter.name,
      stageName: stage.stageName,
      stageId: stage.stageId,
      monsterId: stage.monsterIds.isEmpty ? 'none' : stage.monsterIds.first,
      isBossStage: stage.isBossStage,
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

  void _clearBattleProgress({
    required ChapterConfig chapter,
    required StageConfig stage,
    required String message,
  }) {
    battle = null;
    chapterConfig = chapter;
    stageConfig = stage;
    monsterConfig = null;
    settlementReport = null;
    advancedAfterSettlement = false;
    errorMessage = message;
  }
}

class ChapterBattleProgress {
  const ChapterBattleProgress({
    required this.chapterName,
    required this.stageName,
    required this.stageId,
    required this.monsterId,
    required this.isBossStage,
  });

  final String chapterName;
  final String stageName;
  final String stageId;
  final String monsterId;
  final bool isBossStage;
}
