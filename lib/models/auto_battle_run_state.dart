import 'battle_settlement_report.dart';
import 'battle_state.dart';
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
    );
  }

  AutoBattleRunState addSettlement({
    required BattleSettlementReport report,
    required List<BattleLogEntry> logs,
    required SaveData saveData,
  }) {
    final materials = Map<String, int>.from(totalMaterials);
    for (final material in report.gainedMaterials) {
      materials.update(
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
