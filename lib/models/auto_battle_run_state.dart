import 'battle_settlement_report.dart';
import 'battle_state.dart';
import 'inventory_state.dart';
import 'save_data.dart';

class AutoBattleRunState {
  const AutoBattleRunState({
    required this.saveData,
    this.isRunning = false,
    this.startedAt,
    this.battlesCompleted = 0,
    this.totalExperience = 0,
    this.totalGold = 0,
    this.totalMaterials = const {},
    this.generatedEquipmentCount = 0,
    this.rejectedEquipmentCount = 0,
    this.lastBattleLogs = const [],
    this.stopReason = AutoBattleStopReason.none,
    this.lastSettlementReport,
    this.farmingStageId,
    this.farmingBecauseLevelTooLow = false,
    this.farmingBecauseBattleFailed = false,
    this.farmingBecauseUnsafe = false,
    this.progressionStageId,
    this.autoSalvagedEquipmentCount = 0,
    this.autoSalvageMaterials = const {},
    this.lastProgressionStageId,
    this.lastProgressionStageName,
    this.lastActualStageId,
    this.lastActualStageName,
    this.lastFallbackReason = AutoBattleFallbackReason.none,
    this.lastReadinessReason = AutoBattleReadinessReason.none,
    this.lastEstimatedSecondsToKill,
    this.lastEstimatedIncomingDamage,
    this.lastPlayerEffectiveHp,
    this.lastPlayerDamagePerSecond,
    this.lastMonsterDamagePerHit,
    this.recommendedNextAction = AutoBattleRecommendedAction.none,
    this.lastFailedProgressionStageId,
    this.lastUnsafeProgressionStageId,
  });

  factory AutoBattleRunState.initial(SaveData saveData) {
    return AutoBattleRunState(saveData: saveData);
  }

  final SaveData saveData;
  final bool isRunning;
  final DateTime? startedAt;
  final int battlesCompleted;
  final int totalExperience;
  final int totalGold;
  final Map<String, int> totalMaterials;
  final int generatedEquipmentCount;
  final int rejectedEquipmentCount;
  final List<BattleLogEntry> lastBattleLogs;
  final AutoBattleStopReason stopReason;
  final BattleSettlementReport? lastSettlementReport;
  final String? farmingStageId;
  final bool farmingBecauseLevelTooLow;
  final bool farmingBecauseBattleFailed;
  final bool farmingBecauseUnsafe;
  final String? progressionStageId;
  final int autoSalvagedEquipmentCount;
  final Map<String, int> autoSalvageMaterials;
  final String? lastProgressionStageId;
  final String? lastProgressionStageName;
  final String? lastActualStageId;
  final String? lastActualStageName;
  final AutoBattleFallbackReason lastFallbackReason;
  final AutoBattleReadinessReason lastReadinessReason;
  final double? lastEstimatedSecondsToKill;
  final double? lastEstimatedIncomingDamage;
  final double? lastPlayerEffectiveHp;
  final double? lastPlayerDamagePerSecond;
  final double? lastMonsterDamagePerHit;
  final AutoBattleRecommendedAction recommendedNextAction;
  final String? lastFailedProgressionStageId;
  final String? lastUnsafeProgressionStageId;

  AutoBattleRunState copyWith({
    SaveData? saveData,
    bool? isRunning,
    DateTime? startedAt,
    int? battlesCompleted,
    int? totalExperience,
    int? totalGold,
    Map<String, int>? totalMaterials,
    int? generatedEquipmentCount,
    int? rejectedEquipmentCount,
    List<BattleLogEntry>? lastBattleLogs,
    AutoBattleStopReason? stopReason,
    BattleSettlementReport? lastSettlementReport,
    String? farmingStageId,
    bool clearFarmingStageId = false,
    bool? farmingBecauseLevelTooLow,
    bool? farmingBecauseBattleFailed,
    bool? farmingBecauseUnsafe,
    String? progressionStageId,
    bool clearProgressionStageId = false,
    int? autoSalvagedEquipmentCount,
    Map<String, int>? autoSalvageMaterials,
    String? lastProgressionStageId,
    bool clearLastProgressionStageId = false,
    String? lastProgressionStageName,
    bool clearLastProgressionStageName = false,
    String? lastActualStageId,
    bool clearLastActualStageId = false,
    String? lastActualStageName,
    bool clearLastActualStageName = false,
    AutoBattleFallbackReason? lastFallbackReason,
    AutoBattleReadinessReason? lastReadinessReason,
    double? lastEstimatedSecondsToKill,
    bool clearLastEstimatedSecondsToKill = false,
    double? lastEstimatedIncomingDamage,
    bool clearLastEstimatedIncomingDamage = false,
    double? lastPlayerEffectiveHp,
    bool clearLastPlayerEffectiveHp = false,
    double? lastPlayerDamagePerSecond,
    bool clearLastPlayerDamagePerSecond = false,
    double? lastMonsterDamagePerHit,
    bool clearLastMonsterDamagePerHit = false,
    AutoBattleRecommendedAction? recommendedNextAction,
    String? lastFailedProgressionStageId,
    bool clearLastFailedProgressionStageId = false,
    String? lastUnsafeProgressionStageId,
    bool clearLastUnsafeProgressionStageId = false,
  }) {
    return AutoBattleRunState(
      saveData: saveData ?? this.saveData,
      isRunning: isRunning ?? this.isRunning,
      startedAt: startedAt ?? this.startedAt,
      battlesCompleted: battlesCompleted ?? this.battlesCompleted,
      totalExperience: totalExperience ?? this.totalExperience,
      totalGold: totalGold ?? this.totalGold,
      totalMaterials: totalMaterials ?? this.totalMaterials,
      generatedEquipmentCount:
          generatedEquipmentCount ?? this.generatedEquipmentCount,
      rejectedEquipmentCount:
          rejectedEquipmentCount ?? this.rejectedEquipmentCount,
      lastBattleLogs: lastBattleLogs ?? this.lastBattleLogs,
      stopReason: stopReason ?? this.stopReason,
      lastSettlementReport: lastSettlementReport ?? this.lastSettlementReport,
      farmingStageId:
          clearFarmingStageId ? null : farmingStageId ?? this.farmingStageId,
      farmingBecauseLevelTooLow:
          farmingBecauseLevelTooLow ?? this.farmingBecauseLevelTooLow,
      farmingBecauseBattleFailed:
          farmingBecauseBattleFailed ?? this.farmingBecauseBattleFailed,
      farmingBecauseUnsafe: farmingBecauseUnsafe ?? this.farmingBecauseUnsafe,
      progressionStageId: clearProgressionStageId
          ? null
          : progressionStageId ?? this.progressionStageId,
      autoSalvagedEquipmentCount:
          autoSalvagedEquipmentCount ?? this.autoSalvagedEquipmentCount,
      autoSalvageMaterials: autoSalvageMaterials ?? this.autoSalvageMaterials,
      lastProgressionStageId: clearLastProgressionStageId
          ? null
          : lastProgressionStageId ?? this.lastProgressionStageId,
      lastProgressionStageName: clearLastProgressionStageName
          ? null
          : lastProgressionStageName ?? this.lastProgressionStageName,
      lastActualStageId: clearLastActualStageId
          ? null
          : lastActualStageId ?? this.lastActualStageId,
      lastActualStageName: clearLastActualStageName
          ? null
          : lastActualStageName ?? this.lastActualStageName,
      lastFallbackReason: lastFallbackReason ?? this.lastFallbackReason,
      lastReadinessReason: lastReadinessReason ?? this.lastReadinessReason,
      lastEstimatedSecondsToKill: clearLastEstimatedSecondsToKill
          ? null
          : lastEstimatedSecondsToKill ?? this.lastEstimatedSecondsToKill,
      lastEstimatedIncomingDamage: clearLastEstimatedIncomingDamage
          ? null
          : lastEstimatedIncomingDamage ?? this.lastEstimatedIncomingDamage,
      lastPlayerEffectiveHp: clearLastPlayerEffectiveHp
          ? null
          : lastPlayerEffectiveHp ?? this.lastPlayerEffectiveHp,
      lastPlayerDamagePerSecond: clearLastPlayerDamagePerSecond
          ? null
          : lastPlayerDamagePerSecond ?? this.lastPlayerDamagePerSecond,
      lastMonsterDamagePerHit: clearLastMonsterDamagePerHit
          ? null
          : lastMonsterDamagePerHit ?? this.lastMonsterDamagePerHit,
      recommendedNextAction:
          recommendedNextAction ?? this.recommendedNextAction,
      lastFailedProgressionStageId: clearLastFailedProgressionStageId
          ? null
          : lastFailedProgressionStageId ?? this.lastFailedProgressionStageId,
      lastUnsafeProgressionStageId: clearLastUnsafeProgressionStageId
          ? null
          : lastUnsafeProgressionStageId ?? this.lastUnsafeProgressionStageId,
    );
  }

  AutoBattleRunState addSettlement({
    required BattleSettlementReport report,
    required List<BattleLogEntry> logs,
    required SaveData saveData,
    String? farmingStageId,
    bool farmingBecauseLevelTooLow = false,
    bool farmingBecauseBattleFailed = false,
    bool farmingBecauseUnsafe = false,
    required String progressionStageId,
    String? progressionStageName,
    required String actualStageId,
    String? actualStageName,
    AutoBattleFallbackReason fallbackReason = AutoBattleFallbackReason.none,
    AutoBattleReadinessReason readinessReason = AutoBattleReadinessReason.none,
    double? estimatedSecondsToKill,
    double? estimatedIncomingDamage,
    double? playerEffectiveHp,
    double? playerDamagePerSecond,
    double? monsterDamagePerHit,
    AutoBattleRecommendedAction recommendedNextAction =
        AutoBattleRecommendedAction.none,
    String? failedProgressionStageId,
    String? unsafeProgressionStageId,
    int autoSalvagedCount = 0,
    List<MaterialStack> autoSalvageGainedMaterials = const [],
  }) {
    final materials = Map<String, int>.from(totalMaterials);
    for (final material in report.gainedMaterials) {
      materials.update(
        material.materialId,
        (quantity) => quantity + material.quantity,
        ifAbsent: () => material.quantity,
      );
    }
    final autoSalvageMaterials = Map<String, int>.from(
      this.autoSalvageMaterials,
    );
    for (final material in autoSalvageGainedMaterials) {
      autoSalvageMaterials.update(
        material.materialId,
        (quantity) => quantity + material.quantity,
        ifAbsent: () => material.quantity,
      );
    }

    return copyWith(
      saveData: saveData,
      battlesCompleted: battlesCompleted + 1,
      totalExperience: totalExperience + report.gainedExperience,
      totalGold: totalGold + report.gainedGold,
      totalMaterials: Map.unmodifiable(materials),
      generatedEquipmentCount:
          generatedEquipmentCount + report.generatedEquipment.length,
      rejectedEquipmentCount:
          rejectedEquipmentCount + report.rejectedEquipment.length,
      lastBattleLogs: List.unmodifiable(logs),
      lastSettlementReport: report,
      farmingStageId: farmingStageId,
      clearFarmingStageId: farmingStageId == null,
      farmingBecauseLevelTooLow: farmingBecauseLevelTooLow,
      farmingBecauseBattleFailed: farmingBecauseBattleFailed,
      farmingBecauseUnsafe: farmingBecauseUnsafe,
      progressionStageId: progressionStageId,
      lastProgressionStageId: progressionStageId,
      lastProgressionStageName: progressionStageName,
      clearLastProgressionStageName: progressionStageName == null,
      lastActualStageId: actualStageId,
      lastActualStageName: actualStageName,
      clearLastActualStageName: actualStageName == null,
      lastFallbackReason: fallbackReason,
      lastReadinessReason: readinessReason,
      lastEstimatedSecondsToKill: estimatedSecondsToKill,
      clearLastEstimatedSecondsToKill: estimatedSecondsToKill == null,
      lastEstimatedIncomingDamage: estimatedIncomingDamage,
      clearLastEstimatedIncomingDamage: estimatedIncomingDamage == null,
      lastPlayerEffectiveHp: playerEffectiveHp,
      clearLastPlayerEffectiveHp: playerEffectiveHp == null,
      lastPlayerDamagePerSecond: playerDamagePerSecond,
      clearLastPlayerDamagePerSecond: playerDamagePerSecond == null,
      lastMonsterDamagePerHit: monsterDamagePerHit,
      clearLastMonsterDamagePerHit: monsterDamagePerHit == null,
      recommendedNextAction: recommendedNextAction,
      lastFailedProgressionStageId: failedProgressionStageId,
      clearLastFailedProgressionStageId: failedProgressionStageId == null,
      lastUnsafeProgressionStageId: unsafeProgressionStageId,
      clearLastUnsafeProgressionStageId: unsafeProgressionStageId == null,
      autoSalvagedEquipmentCount:
          autoSalvagedEquipmentCount + autoSalvagedCount,
      autoSalvageMaterials: Map.unmodifiable(autoSalvageMaterials),
    );
  }
}

enum AutoBattleStopReason {
  none,
  manualStop,
  levelTooLow,
  chapterComplete,
  battleNotFinished,
  battleFailed,
  inventoryFull,
  maxBattlesReached,
}

enum AutoBattleFallbackReason {
  none,
  levelTooLow,
  battleFailed,
  unsafeLowDamage,
  unsafeLowSurvivability,
}

enum AutoBattleReadinessReason {
  none,
  safe,
  lowDamage,
  lowSurvivability,
}

enum AutoBattleRecommendedAction {
  none,
  enhanceWeapon,
  enhanceArmorOrHp,
  farmForMaterials,
  equipBetterGear,
  continueProgression,
}
