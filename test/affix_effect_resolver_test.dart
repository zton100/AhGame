import 'package:abyss_relic/models/affix_config.dart';
import 'package:abyss_relic/systems/equipment/affix_effect_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AffixEffectResolver resolves rolled stat modifiers', () {
    final resolver = const AffixEffectResolver();
    final resolved = resolver.resolve(
      affix: AffixConfig.fromJson({
        'id': 'aff_poison_damage',
        'name': 'Poison Damage',
        'type': 'element',
        'tags': ['poison'],
        'minLevel': 1,
        'weight': 100,
        'statModifiers': [
          {
            'stat': 'poison_damage',
            'mode': 'percent',
            'valueFromRoll': true,
          },
        ],
      }),
      rolledAffix: const RolledAffix(
        affixId: 'aff_poison_damage',
        rollValue: 0.12,
        exclusiveGroup: 'element_damage',
      ),
    );

    expect(resolved.warnings, isEmpty);
    expect(resolved.statModifiers.single.stat, 'poison_damage');
    expect(resolved.statModifiers.single.mode, AffixModifierMode.percent);
    expect(resolved.statModifiers.single.value, 0.12);
    expect(resolved.statModifiers.single.sourceAffixId, 'aff_poison_damage');
  });

  test('AffixEffectResolver warns when rolled value is missing', () {
    final resolver = const AffixEffectResolver();
    final resolved = resolver.resolve(
      affix: AffixConfig.fromJson({
        'id': 'aff_poison_damage',
        'name': 'Poison Damage',
        'type': 'element',
        'tags': ['poison'],
        'minLevel': 1,
        'weight': 100,
        'statModifiers': [
          {
            'stat': 'poison_damage',
            'mode': 'percent',
            'valueFromRoll': true,
          },
        ],
      }),
      rolledAffix: const RolledAffix(
        affixId: 'aff_poison_damage',
        rollValue: null,
        exclusiveGroup: null,
      ),
    );

    expect(resolved.statModifiers, isEmpty);
    expect(resolved.warnings.single.code, AffixEffectWarningCode.missingRoll);
  });

  test('AffixEffectResolver resolves status and event effects', () {
    final resolver = const AffixEffectResolver();

    final status = resolver.resolve(
      affix: AffixConfig.fromJson({
        'id': 'aff_apply_status',
        'name': 'Apply Status',
        'type': 'status',
        'tags': ['poison'],
        'minLevel': 1,
        'weight': 100,
        'effect': {
          'effectId': 'apply_status',
          'params': {'status': 'poison_mark'},
        },
      }),
      rolledAffix: const RolledAffix(
        affixId: 'aff_apply_status',
        rollValue: null,
        exclusiveGroup: null,
      ),
    );
    final event = resolver.resolve(
      affix: AffixConfig.fromJson({
        'id': 'aff_poison_can_crit',
        'name': 'Poison Can Crit',
        'type': 'mechanic',
        'tags': ['poison', 'crit'],
        'minLevel': 35,
        'weight': 8,
        'effect': {'effectId': 'poison_can_crit', 'params': {}},
      }),
      rolledAffix: const RolledAffix(
        affixId: 'aff_poison_can_crit',
        rollValue: null,
        exclusiveGroup: 'core_mechanic',
      ),
    );

    expect(status.statusEffects.single.statusId, 'poison_mark');
    expect(status.warnings, isEmpty);
    expect(event.eventTriggers.single.effectId, 'poison_can_crit');
    expect(event.warnings, isEmpty);
  });

  test('AffixEffectResolver reports unknown effect ids', () {
    final resolver = const AffixEffectResolver();
    final resolved = resolver.resolve(
      affix: AffixConfig.fromJson({
        'id': 'aff_unknown',
        'name': 'Unknown',
        'type': 'mechanic',
        'tags': ['weird'],
        'minLevel': 1,
        'weight': 100,
        'effect': {'effectId': 'missing_effect', 'params': {}},
      }),
      rolledAffix: const RolledAffix(
        affixId: 'aff_unknown',
        rollValue: null,
        exclusiveGroup: null,
      ),
    );

    expect(resolved.eventTriggers, isEmpty);
    expect(resolved.warnings.single.code, AffixEffectWarningCode.unknownEffect);
    expect(resolved.warnings.single.effectId, 'missing_effect');
  });
}
