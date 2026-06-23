import 'package:abyss_relic/models/affix_config.dart';
import 'package:abyss_relic/models/data_file_meta.dart';
import 'package:abyss_relic/models/loaded_data_file.dart';
import 'package:abyss_relic/systems/config/game_database.dart';
import 'package:abyss_relic/systems/equipment/affix_roll_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AffixConfig parses stat and mechanic affixes', () {
    final statAffix = AffixConfig.fromJson(_poisonAffix());
    final mechanicAffix = AffixConfig.fromJson({
      'id': 'aff_poison_can_crit',
      'name': 'Poison Can Crit',
      'type': 'mechanic',
      'tags': ['poison', 'crit', 'core'],
      'minLevel': 35,
      'weight': 8,
      'effect': {
        'effectId': 'poison_can_crit',
        'params': {'chance': 1},
      },
    });

    expect(statAffix.rollRange?.min, 0.06);
    expect(statAffix.statModifiers.single.stat, 'poison_damage');
    expect(statAffix.statModifiers.single.mode, AffixModifierMode.percent);
    expect(mechanicAffix.effect?.effectId, 'poison_can_crit');
    expect(mechanicAffix.effect?.params['chance'], 1);
  });

  test('AffixRollService rolls deterministic affixes by seed', () {
    final service = _service();

    final first = service.rollAffixes(
      level: 20,
      allowedTags: const ['poison', 'fire'],
      count: 2,
      seed: 42,
    );
    final second = service.rollAffixes(
      level: 20,
      allowedTags: const ['poison', 'fire'],
      count: 2,
      seed: 42,
    );

    expect(first.map((affix) => affix.affixId), second.map((a) => a.affixId));
    expect(
        first.map((affix) => affix.rollValue), second.map((a) => a.rollValue));
  });

  test('AffixRollService filters by level and tags', () {
    final service = _service();

    final lowLevel = service.candidatesFor(
      level: 1,
      allowedTags: const ['poison', 'core'],
    );
    final fireOnly = service.candidatesFor(
      level: 20,
      allowedTags: const ['fire'],
    );

    expect(lowLevel.map((affix) => affix.id), contains('aff_poison_damage'));
    expect(
        lowLevel.map((affix) => affix.id), isNot(contains('aff_poison_core')));
    expect(fireOnly.map((affix) => affix.id), contains('aff_fire_damage'));
    expect(fireOnly.map((affix) => affix.id),
        isNot(contains('aff_poison_damage')));
  });

  test('AffixRollService respects exclusive groups', () {
    final service = _service();

    final rolled = service.rollAffixes(
      level: 20,
      allowedTags: const ['poison', 'fire'],
      count: 3,
      seed: 7,
    );

    expect(rolled, hasLength(2));
    expect(rolled.map((affix) => affix.exclusiveGroup).toSet(), hasLength(2));
  });

  test('AffixRollService rolls values inside configured steps', () {
    final service = _service();

    final rolled = service
        .rollAffixes(
          level: 20,
          allowedTags: const ['poison'],
          count: 1,
          seed: 99,
        )
        .single;

    expect(rolled.rollValue, isNotNull);
    expect(rolled.rollValue!, greaterThanOrEqualTo(0.06));
    expect(rolled.rollValue!, lessThanOrEqualTo(0.18));
    final stepOffset = (rolled.rollValue! - 0.06) * 100;
    expect(stepOffset, closeTo(stepOffset.round(), 0.000001));
  });
}

AffixRollService _service() {
  final database = GameDatabase.fromFiles([
    LoadedDataFile(
      meta: const DataFileMeta(
        assetPath: 'assets/data/affixes.json',
        schemaVersion: 1,
        recordCount: 4,
        topLevelKeys: ['schemaVersion', 'affixes'],
      ),
      json: {
        'schemaVersion': 1,
        'affixes': [
          _poisonAffix(),
          {
            'id': 'aff_fire_damage',
            'name': 'Fire Damage',
            'type': 'element',
            'tags': ['fire'],
            'minLevel': 1,
            'weight': 100,
            'exclusiveGroup': 'element_damage',
            'rollRange': {'min': 0.05, 'max': 0.17, 'step': 0.01},
            'statModifiers': [
              {
                'stat': 'fire_damage',
                'mode': 'percent',
                'valueFromRoll': true,
              },
            ],
          },
          {
            'id': 'aff_poison_core',
            'name': 'Poison Core',
            'type': 'mechanic',
            'tags': ['poison', 'core'],
            'minLevel': 10,
            'weight': 100,
            'exclusiveGroup': 'core_mechanic',
            'effect': {'effectId': 'poison_core', 'params': {}},
          },
          {
            'id': 'aff_fire_core',
            'name': 'Fire Core',
            'type': 'mechanic',
            'tags': ['fire', 'core'],
            'minLevel': 10,
            'weight': 100,
            'exclusiveGroup': 'core_mechanic',
            'effect': {'effectId': 'fire_core', 'params': {}},
          },
        ],
      },
    ),
  ]);

  return AffixRollService(database);
}

Map<String, Object?> _poisonAffix() {
  return {
    'id': 'aff_poison_damage',
    'name': 'Poison Damage',
    'type': 'element',
    'tags': ['poison'],
    'minLevel': 1,
    'weight': 120,
    'exclusiveGroup': 'element_damage',
    'rollRange': {'min': 0.06, 'max': 0.18, 'step': 0.01},
    'statModifiers': [
      {
        'stat': 'poison_damage',
        'mode': 'percent',
        'valueFromRoll': true,
      },
    ],
  };
}
