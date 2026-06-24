import '../../models/equipment_template.dart';
import '../../models/loot_drop.dart';
import '../config/game_database.dart';
import '../drop/drop_pool_service.dart';

class BattleDropResolutionService {
  const BattleDropResolutionService();

  BattleDropResolution resolve({
    required GameDatabase database,
    required String dropPoolId,
    required String classId,
    required int level,
    required int seed,
  }) {
    final rolledDrops = DropPoolService(database).roll(
      poolId: dropPoolId,
      seed: seed,
    );
    final acceptedDrops = <LootDrop>[];
    final skippedDrops = <LootDrop>[];

    for (final drop in rolledDrops) {
      if (drop.type != LootDropType.equipment) {
        acceptedDrops.add(drop);
        continue;
      }

      final record = database.findRecord('equipment_templates', drop.refId);
      if (record == null) {
        skippedDrops.add(drop);
        continue;
      }

      final template = EquipmentTemplate.fromJson(record);
      final classAllowed = template.allowedClasses.contains('all') ||
          template.allowedClasses.contains(classId);
      if (!classAllowed || level < template.minLevel) {
        skippedDrops.add(drop);
        continue;
      }

      acceptedDrops.add(drop);
    }

    return BattleDropResolution(
      rolledDrops: List.unmodifiable(rolledDrops),
      acceptedDrops: List.unmodifiable(acceptedDrops),
      skippedDrops: List.unmodifiable(skippedDrops),
    );
  }
}

class BattleDropResolution {
  const BattleDropResolution({
    required this.rolledDrops,
    required this.acceptedDrops,
    required this.skippedDrops,
  });

  final List<LootDrop> rolledDrops;
  final List<LootDrop> acceptedDrops;
  final List<LootDrop> skippedDrops;
}
