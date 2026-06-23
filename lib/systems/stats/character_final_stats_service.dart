import '../../models/character_state.dart';
import '../../models/equipment_loadout.dart';
import '../../models/inventory_state.dart';
import '../config/game_database.dart';
import '../inventory/equipment_instance_store.dart';
import 'equipment_stat_modifier_service.dart';
import 'stat_aggregation_service.dart';

class CharacterFinalStatsService {
  const CharacterFinalStatsService({
    StatAggregationService statAggregationService =
        const StatAggregationService(),
    EquipmentStatModifierService equipmentStatModifierService =
        const EquipmentStatModifierService(),
    EquipmentInstanceStore equipmentStore = const EquipmentInstanceStore(),
  })  : _statAggregationService = statAggregationService,
        _equipmentStatModifierService = equipmentStatModifierService,
        _equipmentStore = equipmentStore;

  final StatAggregationService _statAggregationService;
  final EquipmentStatModifierService _equipmentStatModifierService;
  final EquipmentInstanceStore _equipmentStore;

  CharacterFinalStatsResult compute({
    required CharacterState character,
    required EquipmentLoadout loadout,
    required InventoryState inventory,
    required GameDatabase database,
  }) {
    final modifiers = <StatModifier>[];
    final warnings = <CharacterFinalStatsWarning>[];

    for (final entry in loadout.equippedBySlot.entries) {
      final instanceId = entry.value;
      final equipment = _equipmentStore.findInstance(
        state: inventory,
        instanceId: instanceId,
      );
      if (equipment == null) {
        warnings.add(CharacterFinalStatsWarning(
          code: CharacterFinalStatsWarningCode.missingEquipmentInstance,
          equipmentInstanceId: instanceId,
          slotId: entry.key,
          message: 'Equipped equipment instance not found: $instanceId.',
        ));
        continue;
      }

      final equipmentModifiers =
          _equipmentStatModifierService.modifiersForEquipment(
        equipment: equipment,
        database: database,
      );
      modifiers.addAll(equipmentModifiers.modifiers);
      for (final warning in equipmentModifiers.warnings) {
        warnings.add(CharacterFinalStatsWarning(
          code: CharacterFinalStatsWarningCode.equipmentModifierWarning,
          equipmentInstanceId: warning.equipmentInstanceId,
          slotId: entry.key,
          message: warning.message,
        ));
      }
    }

    final computedStats = _statAggregationService.compute(
      base: character.levelStats,
      modifiers: modifiers,
    );

    return CharacterFinalStatsResult(
      computedStats: computedStats,
      appliedModifiers: List.unmodifiable(modifiers),
      warnings: List.unmodifiable(warnings),
    );
  }
}

class CharacterFinalStatsResult {
  const CharacterFinalStatsResult({
    required this.computedStats,
    required this.appliedModifiers,
    required this.warnings,
  });

  final ComputedStats computedStats;
  final List<StatModifier> appliedModifiers;
  final List<CharacterFinalStatsWarning> warnings;
}

class CharacterFinalStatsWarning {
  const CharacterFinalStatsWarning({
    required this.code,
    required this.equipmentInstanceId,
    required this.slotId,
    required this.message,
  });

  final CharacterFinalStatsWarningCode code;
  final String equipmentInstanceId;
  final String slotId;
  final String message;
}

enum CharacterFinalStatsWarningCode {
  missingEquipmentInstance,
  equipmentModifierWarning,
}
