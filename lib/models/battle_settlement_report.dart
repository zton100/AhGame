import 'equipment_instance.dart';
import 'inventory_state.dart';
import 'save_data.dart';

class BattleSettlementReport {
  const BattleSettlementReport({
    required this.accepted,
    required this.reason,
    required this.saveData,
    this.gainedExperience = 0,
    this.gainedGold = 0,
    this.gainedMaterials = const [],
    this.generatedEquipment = const [],
    this.rejectedEquipment = const [],
    this.leveledUp = false,
    this.newLevel,
  });

  final bool accepted;
  final BattleSettlementReason reason;
  final SaveData saveData;
  final int gainedExperience;
  final int gainedGold;
  final List<MaterialStack> gainedMaterials;
  final List<EquipmentInstance> generatedEquipment;
  final List<EquipmentInstance> rejectedEquipment;
  final bool leveledUp;
  final int? newLevel;
}

enum BattleSettlementReason {
  settled,
  notVictory,
}
