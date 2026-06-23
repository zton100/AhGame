import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/inventory_state.dart';
import '../../models/loot_drop.dart';
import '../../models/save_data.dart';
import '../../systems/config/game_database.dart';
import '../../systems/drop/drop_pool_service.dart';
import '../../systems/drop/equipment_loot_materialization_service.dart';
import '../../systems/equipment/affix_roll_service.dart';
import '../../systems/equipment/equipment_generation_service.dart';
import '../../systems/equipment/equipment_template_service.dart';
import '../../systems/equipment/quality_service.dart';
import '../../systems/inventory/equipment_loot_commit_service.dart';
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
      inventory: inventorySaveFromState(committed.state),
    ));
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
    equipmentCapacity: save.equipmentCapacity,
    materials: save.materials,
    lockedEquipmentInstanceIds: save.lockedEquipmentInstanceIds,
  );
}

InventorySave inventorySaveFromState(InventoryState state) {
  return InventorySave(
    equipmentInstanceIds: state.equipmentInstanceIds,
    equipmentInstances: state.equipmentInstances,
    equipmentCapacity: state.equipmentCapacity,
    materials: state.materials,
    lockedEquipmentInstanceIds: state.lockedEquipmentInstanceIds,
  );
}
