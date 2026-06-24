import '../../models/auto_salvage_config.dart';
import '../../models/equipment_instance.dart';
import '../../models/equipment_template.dart';
import '../../models/inventory_state.dart';
import '../build/build_score_service.dart';
import '../build/build_service.dart';
import '../config/game_database.dart';
import 'equipment_instance_store.dart';
import 'equipment_inventory_action_service.dart';
import 'inventory_service.dart';

class AutoSalvageService {
  const AutoSalvageService({
    EquipmentInstanceStore equipmentStore = const EquipmentInstanceStore(),
    InventoryService inventoryService = const InventoryService(),
  })  : _equipmentStore = equipmentStore,
        _inventoryService = inventoryService;

  final EquipmentInstanceStore _equipmentStore;
  final InventoryService _inventoryService;

  AutoSalvageDecision shouldKeep({
    required EquipmentInstance equipment,
    required InventoryState inventory,
    required GameDatabase database,
    required String classId,
    required AutoSalvageConfig config,
    required BuildAssessment assessment,
  }) {
    if (!config.enabled) {
      return const AutoSalvageDecision(
        keep: true,
        reason: AutoSalvageReason.configDisabled,
      );
    }
    if (config.keepLocked && inventory.isLocked(equipment.instanceId)) {
      return const AutoSalvageDecision(
        keep: true,
        reason: AutoSalvageReason.locked,
      );
    }
    if (config.keepEquipped &&
        inventory.equipmentLoadout.equippedBySlot.containsValue(
          equipment.instanceId,
        )) {
      return const AutoSalvageDecision(
        keep: true,
        reason: AutoSalvageReason.equipped,
      );
    }

    final templateRecord = database.findRecord(
      'equipment_templates',
      equipment.templateId,
    );
    if (templateRecord == null) {
      return const AutoSalvageDecision(
        keep: true,
        reason: AutoSalvageReason.unjudgeable,
      );
    }
    final template = EquipmentTemplate.fromJson(templateRecord);
    if (!template.allowedClasses.contains(classId)) {
      return const AutoSalvageDecision(
        keep: true,
        reason: AutoSalvageReason.unjudgeable,
      );
    }

    if (config.keepLegendaryOrAbove &&
        _qualityRank(equipment.qualityId) >= _qualityRank('legendary')) {
      return const AutoSalvageDecision(
        keep: true,
        reason: AutoSalvageReason.legendaryOrAbove,
      );
    }
    if (_qualityRank(equipment.qualityId) >=
        _qualityRank(config.minQualityToKeep)) {
      return const AutoSalvageDecision(
        keep: true,
        reason: AutoSalvageReason.qualityKept,
      );
    }
    if (config.allowedQualityIdsToSalvage.isNotEmpty &&
        !config.allowedQualityIdsToSalvage.contains(equipment.qualityId)) {
      return const AutoSalvageDecision(
        keep: true,
        reason: AutoSalvageReason.qualityNotAllowed,
      );
    }

    final score = BuildScoreService(database).scoreEquipment(
      equipment: equipment,
      assessment: assessment,
    );
    if (score.matchScore >= config.minBuildMatchScoreToKeep) {
      return const AutoSalvageDecision(
        keep: true,
        reason: AutoSalvageReason.highBuildMatch,
      );
    }

    return const AutoSalvageDecision(
      keep: false,
      reason: AutoSalvageReason.lowValue,
    );
  }

  AutoSalvageReport processInventory({
    required InventoryState inventory,
    required GameDatabase database,
    required String classId,
    required AutoSalvageConfig config,
    Iterable<String>? candidateInstanceIds,
  }) {
    if (!config.enabled) {
      return AutoSalvageReport(
        state: inventory,
        salvagedEquipmentIds: const [],
        keptEquipmentIds: inventory.equipmentInstanceIds,
        gainedMaterials: const [],
        reasonByEquipmentId: {
          for (final id in inventory.equipmentInstanceIds)
            id: AutoSalvageReason.configDisabled,
        },
      );
    }

    var state = inventory;
    final equipment = _equipmentStore.listInstancesByInventoryOrder(
      state: inventory,
    );
    final candidates = candidateInstanceIds?.toSet();
    final assessment = BuildService(database).assess(
      classId: classId,
      equipment: equipment,
    );
    final salvaged = <String>[];
    final kept = <String>[];
    final reasons = <String, AutoSalvageReason>{};
    final materials = <String, int>{};

    for (final item in equipment) {
      if (candidates != null && !candidates.contains(item.instanceId)) {
        kept.add(item.instanceId);
        reasons[item.instanceId] = AutoSalvageReason.notCandidate;
        continue;
      }

      final decision = shouldKeep(
        equipment: item,
        inventory: state,
        database: database,
        classId: classId,
        config: config,
        assessment: assessment,
      );
      reasons[item.instanceId] = decision.reason;
      if (decision.keep) {
        kept.add(item.instanceId);
        continue;
      }

      state = _equipmentStore.removeInstance(
        state: state,
        instanceId: item.instanceId,
      );
      final dust = _salvageDustForQuality(item.qualityId);
      state = _inventoryService
          .addMaterial(
            state: state,
            materialId: EquipmentInventoryActionService.salvageDustMaterialId,
            quantity: dust,
          )
          .state;
      materials.update(
        EquipmentInventoryActionService.salvageDustMaterialId,
        (quantity) => quantity + dust,
        ifAbsent: () => dust,
      );
      salvaged.add(item.instanceId);
    }

    return AutoSalvageReport(
      state: state,
      salvagedEquipmentIds: List.unmodifiable(salvaged),
      keptEquipmentIds: List.unmodifiable(kept),
      gainedMaterials: [
        for (final entry in materials.entries)
          MaterialStack(materialId: entry.key, quantity: entry.value),
      ],
      reasonByEquipmentId: Map.unmodifiable(reasons),
    );
  }

  int _salvageDustForQuality(String qualityId) {
    switch (qualityId) {
      case 'rare':
        return 2;
      case 'epic':
        return 4;
      case 'legendary':
        return 8;
      case 'mythic':
        return 12;
      case 'abyss':
        return 20;
      case 'normal':
      case 'magic':
      default:
        return 1;
    }
  }

  int _qualityRank(String qualityId) {
    const order = [
      'normal',
      'magic',
      'rare',
      'epic',
      'legendary',
      'mythic',
      'abyss',
      'forbidden',
    ];
    final index = order.indexOf(qualityId);
    return index < 0 ? 0 : index;
  }
}

class AutoSalvageDecision {
  const AutoSalvageDecision({
    required this.keep,
    required this.reason,
  });

  final bool keep;
  final AutoSalvageReason reason;
}

class AutoSalvageReport {
  const AutoSalvageReport({
    required this.state,
    required this.salvagedEquipmentIds,
    required this.keptEquipmentIds,
    required this.gainedMaterials,
    required this.reasonByEquipmentId,
  });

  final InventoryState state;
  final List<String> salvagedEquipmentIds;
  final List<String> keptEquipmentIds;
  final List<MaterialStack> gainedMaterials;
  final Map<String, AutoSalvageReason> reasonByEquipmentId;

  int get salvagedCount => salvagedEquipmentIds.length;
  int get rejectedCount => keptEquipmentIds.length;
}

enum AutoSalvageReason {
  configDisabled,
  locked,
  equipped,
  legendaryOrAbove,
  qualityKept,
  qualityNotAllowed,
  highBuildMatch,
  lowValue,
  unjudgeable,
  notCandidate,
}
