import '../../models/equipment_instance.dart';
import '../../models/loot_drop.dart';
import '../equipment/equipment_generation_service.dart';

class EquipmentLootMaterializationService {
  const EquipmentLootMaterializationService({
    required EquipmentGenerationService generationService,
  }) : _generationService = generationService;

  final EquipmentGenerationService _generationService;

  EquipmentLootMaterializationResult materialize({
    required Iterable<LootDrop> drops,
    required String classId,
    required int level,
    required String qualityId,
    required int seed,
  }) {
    final generatedEquipment = <EquipmentInstance>[];
    final inventoryDrops = <LootDrop>[];
    final passthroughDrops = <LootDrop>[];
    var index = 0;

    for (final drop in drops) {
      if (drop.type != LootDropType.equipment) {
        passthroughDrops.add(drop);
        inventoryDrops.add(drop);
        continue;
      }

      for (var count = 0; count < drop.quantity; count += 1) {
        final equipment = _generationService.generate(
          templateId: drop.refId,
          qualityId: qualityId,
          classId: classId,
          level: level,
          seed: seed + index,
        );
        generatedEquipment.add(equipment);
        inventoryDrops
            .add(LootDrop.equipment(instanceId: equipment.instanceId));
        index += 1;
      }
    }

    return EquipmentLootMaterializationResult(
      generatedEquipment: List.unmodifiable(generatedEquipment),
      inventoryDrops: List.unmodifiable(inventoryDrops),
      passthroughDrops: List.unmodifiable(passthroughDrops),
    );
  }
}

class EquipmentLootMaterializationResult {
  const EquipmentLootMaterializationResult({
    required this.generatedEquipment,
    required this.inventoryDrops,
    required this.passthroughDrops,
  });

  final List<EquipmentInstance> generatedEquipment;
  final List<LootDrop> inventoryDrops;
  final List<LootDrop> passthroughDrops;
}
