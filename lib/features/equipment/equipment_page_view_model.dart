import '../../models/equipment_instance.dart';
import '../../models/inventory_state.dart';
import '../../systems/build/build_score_service.dart';
import '../../systems/build/build_service.dart';
import '../../systems/build/equipment_compare_service.dart';
import '../../systems/config/game_database.dart';
import 'equipment_card_view_model.dart';

class EquipmentPageViewModelFactory {
  const EquipmentPageViewModelFactory();

  EquipmentPageViewModel create({
    required InventoryState inventory,
    required GameDatabase database,
    String classId = 'exile',
  }) {
    final equipment = [
      for (final instanceId in inventory.equipmentInstanceIds)
        if (inventory.equipmentInstances[instanceId] != null)
          inventory.equipmentInstances[instanceId]!,
    ];
    final missingInstanceIds = [
      for (final instanceId in inventory.equipmentInstanceIds)
        if (inventory.equipmentInstances[instanceId] == null) instanceId,
    ];
    final assessment = BuildService(database).assess(
      classId: classId,
      equipment: equipment,
    );
    final cardFactory = EquipmentCardViewModelFactory(
      database: database,
      compareService: EquipmentCompareService(
        scoreService: BuildScoreService(database),
      ),
    );

    return EquipmentPageViewModel(
      items: [
        for (final item in equipment)
          EquipmentPageItemViewModel(
            equipment: item,
            slotLabel: _slotLabelFor(item, database),
            card: cardFactory.create(
              equipment: item,
              assessment: assessment,
            ),
          ),
      ],
      missingInstanceIds: missingInstanceIds,
    );
  }

  String _slotLabelFor(EquipmentInstance equipment, GameDatabase database) {
    final template = database.findRecord(
      'equipment_templates',
      equipment.templateId,
    );
    return template?['slot'] as String? ?? 'unknown';
  }
}

class EquipmentPageViewModel {
  const EquipmentPageViewModel({
    required this.items,
    required this.missingInstanceIds,
  });

  final List<EquipmentPageItemViewModel> items;
  final List<String> missingInstanceIds;

  bool get isEmpty => items.isEmpty;
}

class EquipmentPageItemViewModel {
  const EquipmentPageItemViewModel({
    required this.equipment,
    required this.slotLabel,
    required this.card,
  });

  final EquipmentInstance equipment;
  final String slotLabel;
  final EquipmentCardViewModel card;
}
