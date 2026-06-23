import '../../models/affix_config.dart';
import '../../models/equipment_instance.dart';
import '../config/game_database.dart';
import '../equipment/affix_effect_resolver.dart';
import '../equipment/affix_roll_service.dart';
import 'stat_aggregation_service.dart';

class EquipmentStatModifierService {
  const EquipmentStatModifierService({
    AffixEffectResolver affixEffectResolver = const AffixEffectResolver(),
  }) : _affixEffectResolver = affixEffectResolver;

  final AffixEffectResolver _affixEffectResolver;

  EquipmentStatModifierResult modifiersForEquipment({
    required EquipmentInstance equipment,
    required GameDatabase database,
  }) {
    final affixService = AffixRollService(database);
    final modifiers = <StatModifier>[];
    final warnings = <EquipmentStatModifierWarning>[];

    for (final stat in equipment.rolledBaseStats) {
      final statKey = StatKey.fromId(stat.stat);
      if (statKey == null) {
        warnings.add(EquipmentStatModifierWarning(
          code: EquipmentStatModifierWarningCode.unknownStat,
          equipmentInstanceId: equipment.instanceId,
          affixId: null,
          stat: stat.stat,
          message: 'Unknown equipment base stat: ${stat.stat}.',
        ));
        continue;
      }

      modifiers.add(StatModifier.flat(
        stat: statKey,
        value: stat.value,
        source: 'equipment:${equipment.instanceId}:base:${stat.stat}',
      ));
    }

    for (final rolledAffix in equipment.rolledAffixes) {
      final affix = _findAffix(
        affixService: affixService,
        equipment: equipment,
        rolledAffix: rolledAffix,
        warnings: warnings,
      );
      if (affix == null) {
        continue;
      }

      final resolved = _affixEffectResolver.resolve(
        affix: affix,
        rolledAffix: rolledAffix,
      );
      for (final warning in resolved.warnings) {
        warnings.add(EquipmentStatModifierWarning(
          code: EquipmentStatModifierWarningCode.affixResolution,
          equipmentInstanceId: equipment.instanceId,
          affixId: warning.affixId,
          stat: null,
          message: warning.message,
        ));
      }

      for (final resolvedModifier in resolved.statModifiers) {
        final statKey = StatKey.fromId(resolvedModifier.stat);
        if (statKey == null) {
          warnings.add(EquipmentStatModifierWarning(
            code: EquipmentStatModifierWarningCode.unknownStat,
            equipmentInstanceId: equipment.instanceId,
            affixId: rolledAffix.affixId,
            stat: resolvedModifier.stat,
            message: 'Unknown affix stat: ${resolvedModifier.stat}.',
          ));
          continue;
        }

        modifiers.add(_statModifierFromResolved(
          statKey: statKey,
          resolvedModifier: resolvedModifier,
          equipment: equipment,
        ));
      }
    }

    return EquipmentStatModifierResult(
      modifiers: List.unmodifiable(modifiers),
      warnings: List.unmodifiable(warnings),
    );
  }

  AffixConfig? _findAffix({
    required AffixRollService affixService,
    required EquipmentInstance equipment,
    required RolledAffix rolledAffix,
    required List<EquipmentStatModifierWarning> warnings,
  }) {
    try {
      return affixService.requireAffix(rolledAffix.affixId);
    } on StateError catch (error) {
      warnings.add(EquipmentStatModifierWarning(
        code: EquipmentStatModifierWarningCode.missingAffix,
        equipmentInstanceId: equipment.instanceId,
        affixId: rolledAffix.affixId,
        stat: null,
        message: error.message,
      ));
      return null;
    }
  }

  StatModifier _statModifierFromResolved({
    required StatKey statKey,
    required ResolvedAffixStatModifier resolvedModifier,
    required EquipmentInstance equipment,
  }) {
    final source =
        'equipment:${equipment.instanceId}:affix:${resolvedModifier.sourceAffixId}';
    switch (resolvedModifier.mode) {
      case AffixModifierMode.flat:
        return StatModifier.flat(
          stat: statKey,
          value: resolvedModifier.value,
          source: source,
        );
      case AffixModifierMode.percent:
        return StatModifier.percent(
          stat: statKey,
          value: resolvedModifier.value,
          source: source,
        );
      case AffixModifierMode.more:
        return StatModifier.more(
          stat: statKey,
          value: resolvedModifier.value,
          source: source,
        );
      case AffixModifierMode.less:
        return StatModifier.less(
          stat: statKey,
          value: resolvedModifier.value,
          source: source,
        );
    }
  }
}

class EquipmentStatModifierResult {
  const EquipmentStatModifierResult({
    required this.modifiers,
    required this.warnings,
  });

  final List<StatModifier> modifiers;
  final List<EquipmentStatModifierWarning> warnings;
}

class EquipmentStatModifierWarning {
  const EquipmentStatModifierWarning({
    required this.code,
    required this.equipmentInstanceId,
    required this.affixId,
    required this.stat,
    required this.message,
  });

  final EquipmentStatModifierWarningCode code;
  final String equipmentInstanceId;
  final String? affixId;
  final String? stat;
  final String message;
}

enum EquipmentStatModifierWarningCode {
  unknownStat,
  missingAffix,
  affixResolution,
}
