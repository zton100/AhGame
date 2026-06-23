import '../../models/affix_config.dart';
import '../config/effect_registry.dart';

class AffixEffectResolver {
  const AffixEffectResolver({
    EffectRegistry effectRegistry = const EffectRegistry(),
  }) : _effectRegistry = effectRegistry;

  final EffectRegistry _effectRegistry;

  ResolvedAffixEffects resolve({
    required AffixConfig affix,
    required RolledAffix rolledAffix,
  }) {
    final statModifiers = <ResolvedAffixStatModifier>[];
    final statusEffects = <ResolvedAffixStatusEffect>[];
    final eventTriggers = <ResolvedAffixEventTrigger>[];
    final warnings = <AffixEffectWarning>[];

    for (final modifier in affix.statModifiers) {
      final value = _valueForModifier(
        affix: affix,
        rolledAffix: rolledAffix,
        modifier: modifier,
        warnings: warnings,
      );
      if (value == null) {
        continue;
      }

      statModifiers.add(ResolvedAffixStatModifier(
        stat: modifier.stat,
        mode: modifier.mode,
        value: value,
        sourceAffixId: affix.id,
      ));
    }

    final effect = affix.effect;
    if (effect != null) {
      if (!_effectRegistry.contains(effect.effectId)) {
        warnings.add(AffixEffectWarning(
          code: AffixEffectWarningCode.unknownEffect,
          affixId: affix.id,
          effectId: effect.effectId,
          message: 'Unknown affix effectId "${effect.effectId}".',
        ));
      } else if (effect.effectId == 'stat_bonus') {
        final modifier = _statModifierFromEffect(
          affix: affix,
          effect: effect,
          warnings: warnings,
        );
        if (modifier != null) {
          statModifiers.add(modifier);
        }
      } else if (effect.effectId == 'apply_status') {
        final statusId = effect.params['status'];
        if (statusId is String && statusId.isNotEmpty) {
          statusEffects.add(ResolvedAffixStatusEffect(
            statusId: statusId,
            params: effect.params,
            sourceAffixId: affix.id,
          ));
        } else {
          warnings.add(AffixEffectWarning(
            code: AffixEffectWarningCode.invalidParams,
            affixId: affix.id,
            effectId: effect.effectId,
            message: 'apply_status requires a non-empty status param.',
          ));
        }
      } else {
        eventTriggers.add(ResolvedAffixEventTrigger(
          effectId: effect.effectId,
          params: effect.params,
          sourceAffixId: affix.id,
        ));
      }
    }

    return ResolvedAffixEffects(
      statModifiers: List.unmodifiable(statModifiers),
      statusEffects: List.unmodifiable(statusEffects),
      eventTriggers: List.unmodifiable(eventTriggers),
      warnings: List.unmodifiable(warnings),
    );
  }

  double? _valueForModifier({
    required AffixConfig affix,
    required RolledAffix rolledAffix,
    required AffixStatModifierConfig modifier,
    required List<AffixEffectWarning> warnings,
  }) {
    if (modifier.valueFromRoll) {
      final rollValue = rolledAffix.rollValue;
      if (rollValue != null) {
        return rollValue;
      }

      warnings.add(AffixEffectWarning(
        code: AffixEffectWarningCode.missingRoll,
        affixId: affix.id,
        effectId: affix.effect?.effectId,
        message: 'Affix ${affix.id} requires a rolled value.',
      ));
      return null;
    }

    final value = modifier.value;
    if (value != null) {
      return value;
    }

    warnings.add(AffixEffectWarning(
      code: AffixEffectWarningCode.invalidParams,
      affixId: affix.id,
      effectId: affix.effect?.effectId,
      message: 'Affix ${affix.id} stat modifier requires a value.',
    ));
    return null;
  }

  ResolvedAffixStatModifier? _statModifierFromEffect({
    required AffixConfig affix,
    required AffixEffectConfig effect,
    required List<AffixEffectWarning> warnings,
  }) {
    final stat = effect.params['stat'];
    final mode = effect.params['mode'];
    final value = effect.params['value'];

    if (stat is String && mode is String && value is num) {
      return ResolvedAffixStatModifier(
        stat: stat,
        mode: AffixModifierMode.fromId(mode),
        value: value.toDouble(),
        sourceAffixId: affix.id,
      );
    }

    warnings.add(AffixEffectWarning(
      code: AffixEffectWarningCode.invalidParams,
      affixId: affix.id,
      effectId: effect.effectId,
      message: 'stat_bonus requires stat, mode, and value params.',
    ));
    return null;
  }
}

class ResolvedAffixEffects {
  const ResolvedAffixEffects({
    required this.statModifiers,
    required this.statusEffects,
    required this.eventTriggers,
    required this.warnings,
  });

  final List<ResolvedAffixStatModifier> statModifiers;
  final List<ResolvedAffixStatusEffect> statusEffects;
  final List<ResolvedAffixEventTrigger> eventTriggers;
  final List<AffixEffectWarning> warnings;
}

class ResolvedAffixStatModifier {
  const ResolvedAffixStatModifier({
    required this.stat,
    required this.mode,
    required this.value,
    required this.sourceAffixId,
  });

  final String stat;
  final AffixModifierMode mode;
  final double value;
  final String sourceAffixId;
}

class ResolvedAffixStatusEffect {
  const ResolvedAffixStatusEffect({
    required this.statusId,
    required this.params,
    required this.sourceAffixId,
  });

  final String statusId;
  final Map<String, Object?> params;
  final String sourceAffixId;
}

class ResolvedAffixEventTrigger {
  const ResolvedAffixEventTrigger({
    required this.effectId,
    required this.params,
    required this.sourceAffixId,
  });

  final String effectId;
  final Map<String, Object?> params;
  final String sourceAffixId;
}

class AffixEffectWarning {
  const AffixEffectWarning({
    required this.code,
    required this.affixId,
    required this.effectId,
    required this.message,
  });

  final AffixEffectWarningCode code;
  final String affixId;
  final String? effectId;
  final String message;
}

enum AffixEffectWarningCode {
  unknownEffect,
  missingRoll,
  invalidParams,
}
