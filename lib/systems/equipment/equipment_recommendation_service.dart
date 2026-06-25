import '../../models/equipment_instance.dart';
import '../../models/equipment_loadout.dart';
import '../../models/equipment_template.dart';
import '../../models/inventory_state.dart';
import '../build/build_score_service.dart';
import '../build/build_service.dart';
import '../build/equipment_compare_service.dart';
import '../config/game_database.dart';
import 'equipment_service.dart';

class EquipmentRecommendationService {
  const EquipmentRecommendationService({
    EquipmentService equipmentService = const EquipmentService(),
  }) : _equipmentService = equipmentService;

  final EquipmentService _equipmentService;

  EquipmentRecommendationResult recommendBestUpgrade({
    required InventoryState inventory,
    required GameDatabase database,
    required String classId,
    required int level,
  }) {
    final assessment = BuildService(database).assess(classId: classId);
    final compareService = EquipmentCompareService(
      scoreService: BuildScoreService(database),
    );
    EquipmentRecommendationCandidate? best;

    for (final instanceId in inventory.equipmentInstanceIds) {
      final equipment = inventory.equipmentInstances[instanceId];
      if (equipment == null) {
        continue;
      }
      final template = _templateFor(database, equipment);
      if (template == null || !_canEquip(template, classId, level)) {
        continue;
      }

      final equippedId = inventory.equipmentLoadout.equippedInstanceId(
        template.slot,
      );
      if (equippedId == equipment.instanceId) {
        continue;
      }
      final equipped =
          equippedId == null ? null : inventory.equipmentInstances[equippedId];
      final comparison = compareService.compare(
        candidate: equipment,
        equipped: equipped,
        assessment: assessment,
      );
      if (comparison.recommendation != EquipmentRecommendation.upgrade &&
          comparison.attackDelta <= 0) {
        continue;
      }

      final candidate = EquipmentRecommendationCandidate(
        equipment: equipment,
        template: template,
        matchScoreDelta: comparison.matchScoreDelta,
        attackDelta: comparison.attackDelta,
      );
      if (best == null || _isBetter(candidate, best)) {
        best = candidate;
      }
    }

    if (best == null) {
      return EquipmentRecommendationResult(
        accepted: false,
        reason: EquipmentRecommendationReason.noUpgradeFound,
        loadout: inventory.equipmentLoadout,
      );
    }

    final loadout = _equipmentService.equipFromInventory(
      loadout: inventory.equipmentLoadout,
      inventory: inventory,
      instanceId: best.equipment.instanceId,
      template: best.template,
      classId: classId,
      level: level,
    );

    return EquipmentRecommendationResult(
      accepted: true,
      reason: EquipmentRecommendationReason.upgradeFound,
      loadout: loadout,
      candidate: best,
    );
  }

  bool _isBetter(
    EquipmentRecommendationCandidate candidate,
    EquipmentRecommendationCandidate current,
  ) {
    if (candidate.matchScoreDelta != current.matchScoreDelta) {
      return candidate.matchScoreDelta > current.matchScoreDelta;
    }

    return candidate.attackDelta > current.attackDelta;
  }

  EquipmentTemplate? _templateFor(
    GameDatabase database,
    EquipmentInstance equipment,
  ) {
    final record = database.findRecord(
      'equipment_templates',
      equipment.templateId,
    );
    if (record == null) {
      return null;
    }

    return EquipmentTemplate.fromJson(record);
  }

  bool _canEquip(EquipmentTemplate template, String classId, int level) {
    if (level < template.minLevel) {
      return false;
    }
    return template.allowedClasses.contains('all') ||
        template.allowedClasses.contains(classId);
  }
}

class EquipmentRecommendationResult {
  const EquipmentRecommendationResult({
    required this.accepted,
    required this.reason,
    required this.loadout,
    this.candidate,
  });

  final bool accepted;
  final EquipmentRecommendationReason reason;
  final EquipmentLoadout loadout;
  final EquipmentRecommendationCandidate? candidate;
}

class EquipmentRecommendationCandidate {
  const EquipmentRecommendationCandidate({
    required this.equipment,
    required this.template,
    required this.matchScoreDelta,
    required this.attackDelta,
  });

  final EquipmentInstance equipment;
  final EquipmentTemplate template;
  final double matchScoreDelta;
  final double attackDelta;
}

enum EquipmentRecommendationReason {
  upgradeFound,
  noUpgradeFound,
}
