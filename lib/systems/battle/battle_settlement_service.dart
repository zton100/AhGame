import '../../models/battle_settlement_report.dart';
import '../../models/battle_state.dart';
import '../../models/equipment_template.dart';
import '../../models/inventory_state.dart';
import '../../models/loot_drop.dart';
import '../../models/monster_config.dart';
import '../../models/save_data.dart';
import '../character/level_service.dart';
import '../config/game_database.dart';
import '../drop/equipment_loot_materialization_service.dart';
import '../equipment/affix_roll_service.dart';
import '../equipment/equipment_generation_service.dart';
import '../equipment/equipment_template_service.dart';
import '../equipment/quality_service.dart';
import '../inventory/equipment_loot_commit_service.dart';
import '../inventory/inventory_service.dart';
import 'battle_drop_resolution_service.dart';

class BattleSettlementService {
  const BattleSettlementService({
    InventoryService inventoryService = const InventoryService(),
    EquipmentLootCommitService equipmentLootCommitService =
        const EquipmentLootCommitService(),
    BattleDropResolutionService dropResolutionService =
        const BattleDropResolutionService(),
  })  : _inventoryService = inventoryService,
        _equipmentLootCommitService = equipmentLootCommitService,
        _dropResolutionService = dropResolutionService;

  static const goldMaterialId = 'gold';

  final InventoryService _inventoryService;
  final EquipmentLootCommitService _equipmentLootCommitService;
  final BattleDropResolutionService _dropResolutionService;

  BattleSettlementReport settle({
    required BattleState battle,
    required MonsterConfig monster,
    required SaveData saveData,
    required GameDatabase database,
    int seed = 1,
  }) {
    if (battle.result != BattleResult.victory) {
      return BattleSettlementReport(
        accepted: false,
        reason: BattleSettlementReason.notVictory,
        saveData: saveData,
      );
    }

    final initialLevel = saveData.playerProgress.level;
    var currentSave = LevelService(database: database).addExperience(
      saveData,
      monster.rewards.experience,
    );
    var inventory = _inventoryStateFromSave(currentSave.inventory);
    final gainedMaterials = <MaterialStack>[];

    if (monster.rewards.gold > 0) {
      inventory = _addMaterial(
        inventory: inventory,
        materialId: goldMaterialId,
        quantity: monster.rewards.gold,
      );
      gainedMaterials.add(MaterialStack(
        materialId: goldMaterialId,
        quantity: monster.rewards.gold,
      ));
    }

    for (final entry in monster.rewards.materials.entries) {
      if (entry.value <= 0) {
        continue;
      }
      inventory = _addMaterial(
        inventory: inventory,
        materialId: entry.key,
        quantity: entry.value,
      );
      gainedMaterials.add(MaterialStack(
        materialId: entry.key,
        quantity: entry.value,
      ));
    }

    final dropResolution = _dropResolutionService.resolve(
      database: database,
      dropPoolId: monster.dropPoolId,
      classId: currentSave.playerProgress.currentClassId,
      level: currentSave.playerProgress.level,
      seed: seed,
    );
    final materialized = EquipmentLootMaterializationService(
      generationService: EquipmentGenerationService(
        templateService: EquipmentTemplateService(database),
        qualityService: QualityService(database),
        affixRollService: AffixRollService(database),
      ),
    ).materialize(
      drops: dropResolution.acceptedDrops,
      classId: currentSave.playerProgress.currentClassId,
      level: currentSave.playerProgress.level,
      qualityId: _qualityIdForDropPool(
        database: database,
        drops: dropResolution.acceptedDrops,
      ),
      seed: seed,
    );
    final committed = _equipmentLootCommitService.commitMaterialized(
      state: inventory,
      materialized: materialized,
    );
    inventory = committed.state;

    currentSave = currentSave.copyWith(
      inventory: _inventorySaveFromState(
        inventory,
        previous: currentSave.inventory,
      ),
    );

    return BattleSettlementReport(
      accepted: true,
      reason: BattleSettlementReason.settled,
      saveData: currentSave,
      gainedExperience: monster.rewards.experience,
      gainedGold: monster.rewards.gold,
      gainedMaterials: List.unmodifiable(gainedMaterials),
      generatedEquipment: committed.acceptedEquipment,
      rejectedEquipment: committed.rejectedEquipment,
      leveledUp: currentSave.playerProgress.level > initialLevel,
      newLevel: currentSave.playerProgress.level,
    );
  }

  InventoryState _addMaterial({
    required InventoryState inventory,
    required String materialId,
    required int quantity,
  }) {
    return _inventoryService
        .addMaterial(
          state: inventory,
          materialId: materialId,
          quantity: quantity,
        )
        .state;
  }

  String _qualityIdForDropPool({
    required GameDatabase database,
    required Iterable<LootDrop> drops,
  }) {
    for (final drop in drops) {
      if (drop.type != LootDropType.equipment) {
        continue;
      }
      final record = database.findRecord('equipment_templates', drop.refId);
      if (record == null) {
        continue;
      }
      final template = EquipmentTemplate.fromJson(record);
      if (template.qualityPool.isNotEmpty) {
        return template.qualityPool.first;
      }
    }

    return 'normal';
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
  required InventorySave previous,
}) {
  return InventorySave(
    equipmentInstanceIds: state.equipmentInstanceIds,
    equipmentInstances: state.equipmentInstances,
    equipmentLoadout: state.equipmentLoadout,
    equipmentCapacity: state.equipmentCapacity,
    materials: state.materials,
    lockedEquipmentInstanceIds: state.lockedEquipmentInstanceIds,
    autoSalvageConfig: previous.autoSalvageConfig,
  );
}
