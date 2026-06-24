import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/inventory_state.dart';
import '../../models/loot_drop.dart';
import '../../models/auto_salvage_config.dart';
import '../../models/save_data.dart';
import '../../models/equipment_template.dart';
import '../../systems/config/game_database.dart';
import '../../systems/drop/drop_pool_service.dart';
import '../../systems/drop/equipment_loot_materialization_service.dart';
import '../../systems/equipment/affix_roll_service.dart';
import '../../systems/equipment/equipment_generation_service.dart';
import '../../systems/equipment/equipment_service.dart';
import '../../systems/equipment/equipment_template_service.dart';
import '../../systems/equipment/quality_service.dart';
import '../../systems/inventory/equipment_inventory_action_service.dart';
import '../../systems/inventory/equipment_loot_commit_service.dart';
import '../../systems/inventory/auto_salvage_service.dart';
import '../../systems/save/in_memory_save_store.dart';
import '../../systems/save/save_service.dart';

final _fallbackSaveStore = InMemorySaveStore();

final saveServiceProvider = Provider<SaveService>((ref) {
  return SaveService(store: _fallbackSaveStore);
});

final playerSaveProvider =
    AsyncNotifierProvider<PlayerSaveController, SaveData>(
  PlayerSaveController.new,
);

class PlayerSaveController extends AsyncNotifier<SaveData> {
  @override
  Future<SaveData> build() {
    return ref.watch(saveServiceProvider).loadOrCreate();
  }

  Future<void> save(SaveData saveData) async {
    final service = ref.read(saveServiceProvider);
    await service.save(saveData);
    state = AsyncData(await service.loadOrCreate());
  }

  Future<void> generateTestEquipment(GameDatabase database) async {
    final currentSave =
        state.valueOrNull ?? await ref.read(saveServiceProvider).loadOrCreate();
    final equipmentDrop = _testEquipmentDrop(database);
    final materialized = EquipmentLootMaterializationService(
      generationService: EquipmentGenerationService(
        templateService: EquipmentTemplateService(database),
        qualityService: QualityService(database),
        affixRollService: AffixRollService(database),
      ),
    ).materialize(
      drops: [equipmentDrop],
      classId: currentSave.playerProgress.currentClassId,
      level: currentSave.playerProgress.level,
      qualityId: 'rare',
      seed: DateTime.now().microsecondsSinceEpoch,
    );
    final committed = const EquipmentLootCommitService().commitMaterialized(
      state: inventoryStateFromSave(currentSave.inventory),
      materialized: materialized,
    );

    await save(currentSave.copyWith(
      inventory: inventorySaveFromState(
        committed.state,
        autoSalvageConfig: currentSave.inventory.autoSalvageConfig,
      ),
    ));
  }

  Future<void> lockEquipment(String instanceId) async {
    final currentSave =
        state.valueOrNull ?? await ref.read(saveServiceProvider).loadOrCreate();
    await save(currentSave.copyWith(
      inventory: currentSave.inventory.lockEquipment(instanceId),
    ));
  }

  Future<void> unlockEquipment(String instanceId) async {
    final currentSave =
        state.valueOrNull ?? await ref.read(saveServiceProvider).loadOrCreate();
    await save(currentSave.copyWith(
      inventory: currentSave.inventory.unlockEquipment(instanceId),
    ));
  }

  Future<void> equipEquipment({
    required GameDatabase database,
    required String instanceId,
  }) async {
    final currentSave =
        state.valueOrNull ?? await ref.read(saveServiceProvider).loadOrCreate();
    final inventory = inventoryStateFromSave(currentSave.inventory);
    final equipment = inventory.equipmentInstances[instanceId];
    if (equipment == null) {
      throw StateError('Equipment instance not found: $instanceId');
    }
    final templateRecord = database.findRecord(
      'equipment_templates',
      equipment.templateId,
    );
    if (templateRecord == null) {
      throw StateError('Equipment template not found: ${equipment.templateId}');
    }

    final loadout = const EquipmentService().equipFromInventory(
      loadout: inventory.equipmentLoadout,
      inventory: inventory,
      instanceId: instanceId,
      template: EquipmentTemplate.fromJson(templateRecord),
      classId: currentSave.playerProgress.currentClassId,
      level: currentSave.playerProgress.level,
    );

    await save(currentSave.copyWith(
      inventory: currentSave.inventory.copyWith(equipmentLoadout: loadout),
    ));
  }

  Future<EquipmentSalvageResult> salvageEquipment(String instanceId) async {
    final currentSave =
        state.valueOrNull ?? await ref.read(saveServiceProvider).loadOrCreate();
    final inventory = inventoryStateFromSave(currentSave.inventory);
    final result = const EquipmentInventoryActionService().salvage(
      state: inventory,
      loadout: inventory.equipmentLoadout,
      instanceId: instanceId,
    );
    if (!result.accepted) {
      return result;
    }

    await save(currentSave.copyWith(
      inventory: inventorySaveFromState(
        result.state,
        autoSalvageConfig: currentSave.inventory.autoSalvageConfig,
      ),
    ));
    return result;
  }

  Future<void> updateAutoSalvageConfig(AutoSalvageConfig config) async {
    final currentSave =
        state.valueOrNull ?? await ref.read(saveServiceProvider).loadOrCreate();
    await save(currentSave.copyWith(
      inventory: currentSave.inventory.copyWith(autoSalvageConfig: config),
    ));
  }

  Future<AutoSalvageReport> autoSalvageEquipment({
    required GameDatabase database,
    required Iterable<String> candidateInstanceIds,
  }) async {
    final currentSave =
        state.valueOrNull ?? await ref.read(saveServiceProvider).loadOrCreate();
    final report = const AutoSalvageService().processInventory(
      inventory: inventoryStateFromSave(currentSave.inventory),
      database: database,
      classId: currentSave.playerProgress.currentClassId,
      config: currentSave.inventory.autoSalvageConfig.copyWith(enabled: true),
      candidateInstanceIds: candidateInstanceIds,
    );
    if (report.salvagedCount > 0) {
      await save(currentSave.copyWith(
        inventory: inventorySaveFromState(
          report.state,
          autoSalvageConfig: currentSave.inventory.autoSalvageConfig,
        ),
      ));
    }

    return report;
  }

  LootDrop _testEquipmentDrop(GameDatabase database) {
    final dropPoolService = DropPoolService(database);
    for (var seed = 1; seed <= 500; seed += 1) {
      final drops = dropPoolService.roll(poolId: 'drop_chapter_1', seed: seed);
      for (final drop in drops) {
        if (drop.type == LootDropType.equipment) {
          return drop;
        }
      }
    }

    throw StateError('No equipment drop found in drop_chapter_1.');
  }
}

InventoryState inventoryStateFromSave(InventorySave save) {
  return InventoryState(
    equipmentInstanceIds: save.equipmentInstanceIds,
    equipmentInstances: save.equipmentInstances,
    equipmentLoadout: save.equipmentLoadout,
    equipmentCapacity: save.equipmentCapacity,
    materials: save.materials,
    lockedEquipmentInstanceIds: save.lockedEquipmentInstanceIds,
  );
}

InventorySave inventorySaveFromState(
  InventoryState state, {
  AutoSalvageConfig autoSalvageConfig = AutoSalvageConfig.defaults,
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
