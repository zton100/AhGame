import '../../models/equipment_instance.dart';
import '../../models/inventory_state.dart';
import '../../systems/build/build_score_service.dart';
import '../../systems/build/build_service.dart';
import '../../systems/build/equipment_compare_service.dart';
import '../../systems/config/game_database.dart';
import '../../systems/equipment/quality_rank.dart';
import '../common/game_text_labels.dart';
import 'equipment_card_view_model.dart';

class EquipmentPageViewModelFactory {
  const EquipmentPageViewModelFactory();

  EquipmentPageViewModel create({
    required InventoryState inventory,
    required GameDatabase database,
    required String classId,
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
            isLocked: inventory.isLocked(item.instanceId),
            isEquipped: inventory.equipmentLoadout.equippedBySlot.containsValue(
              item.instanceId,
            ),
            isCurrentClassUsable: _isUsableForClass(
              item,
              database: database,
              classId: classId,
            ),
            card: cardFactory.create(
              equipment: item,
              assessment: assessment,
              equipped: _equippedForSlot(
                item,
                inventory: inventory,
                database: database,
              ),
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
    return slotLabel(template?['slot'] as String? ?? 'unknown');
  }

  EquipmentInstance? _equippedForSlot(
    EquipmentInstance equipment, {
    required InventoryState inventory,
    required GameDatabase database,
  }) {
    final template = database.findRecord(
      'equipment_templates',
      equipment.templateId,
    );
    final slotId = template?['slot'] as String?;
    if (slotId == null) {
      return null;
    }

    final equippedId = inventory.equipmentLoadout.equippedBySlot[slotId];
    if (equippedId == null || equippedId == equipment.instanceId) {
      return null;
    }

    return inventory.equipmentInstances[equippedId];
  }

  bool _isUsableForClass(
    EquipmentInstance equipment, {
    required GameDatabase database,
    required String classId,
  }) {
    final template = database.findRecord(
      'equipment_templates',
      equipment.templateId,
    );
    final allowedClasses = List<String>.from(
      template?['allowedClasses'] as List? ?? const [],
    );
    return allowedClasses.contains(classId);
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

  List<EquipmentPageItemViewModel> visibleItems({
    required EquipmentPageFilter filter,
    required EquipmentPageSort sort,
  }) {
    final filtered = [
      for (final item in items)
        if (_matchesFilter(item, filter)) item,
    ];
    filtered.sort((a, b) {
      switch (sort) {
        case EquipmentPageSort.newestFirst:
          return b.equipment.createdAt.compareTo(a.equipment.createdAt);
        case EquipmentPageSort.qualityHighToLow:
          return qualityRank(b.card.qualityId).compareTo(
            qualityRank(a.card.qualityId),
          );
        case EquipmentPageSort.buildMatchScoreHighToLow:
          return b.card.matchScore.compareTo(a.card.matchScore);
      }
    });
    return filtered;
  }

  bool _matchesFilter(
    EquipmentPageItemViewModel item,
    EquipmentPageFilter filter,
  ) {
    switch (filter) {
      case EquipmentPageFilter.all:
        return true;
      case EquipmentPageFilter.equipped:
        return item.isEquipped;
      case EquipmentPageFilter.locked:
        return item.isLocked;
      case EquipmentPageFilter.rarePlus:
        return qualityRank(item.card.qualityId) >= qualityRank('rare');
      case EquipmentPageFilter.legendaryPlus:
        return qualityRank(item.card.qualityId) >= qualityRank('legendary');
      case EquipmentPageFilter.currentClassUsable:
        return item.isCurrentClassUsable;
    }
  }
}

class EquipmentPageItemViewModel {
  const EquipmentPageItemViewModel({
    required this.equipment,
    required this.slotLabel,
    required this.isLocked,
    required this.isEquipped,
    required this.isCurrentClassUsable,
    required this.card,
  });

  final EquipmentInstance equipment;
  final String slotLabel;
  final bool isLocked;
  final bool isEquipped;
  final bool isCurrentClassUsable;
  final EquipmentCardViewModel card;
}

enum EquipmentPageFilter {
  all('全部'),
  equipped('已穿戴'),
  locked('已锁定'),
  rarePlus('稀有+'),
  legendaryPlus('传奇+'),
  currentClassUsable('当前职业可用');

  const EquipmentPageFilter(this.label);

  final String label;
}

enum EquipmentPageSort {
  newestFirst('最新优先'),
  qualityHighToLow('品质从高到低'),
  buildMatchScoreHighToLow('构筑匹配分从高到低');

  const EquipmentPageSort(this.label);

  final String label;
}
