import 'dart:math' as math;

import '../../models/stat_block.dart';

class StatAggregationService {
  const StatAggregationService();

  ComputedStats compute({
    required StatBlock base,
    Iterable<StatModifier> modifiers = const [],
  }) {
    final breakdowns = {
      for (final key in StatKey.values)
        key: StatBreakdown(base: _baseValueFor(base, key)),
    };

    for (final modifier in modifiers) {
      breakdowns[modifier.stat] = breakdowns[modifier.stat]!.apply(modifier);
    }

    return ComputedStats(
      finalStats: StatBlock(
        hp: breakdowns[StatKey.hp]!.finalValue,
        attack: breakdowns[StatKey.attack]!.finalValue,
        armor: breakdowns[StatKey.armor]!.finalValue,
      ),
      breakdowns: Map.unmodifiable(breakdowns),
    );
  }

  double _baseValueFor(StatBlock base, StatKey key) {
    switch (key) {
      case StatKey.hp:
        return base.hp;
      case StatKey.attack:
        return base.attack;
      case StatKey.armor:
        return base.armor;
    }
  }
}

class ComputedStats {
  const ComputedStats({
    required this.finalStats,
    required this.breakdowns,
  });

  final StatBlock finalStats;
  final Map<StatKey, StatBreakdown> breakdowns;

  StatBreakdown breakdownFor(StatKey stat) {
    return breakdowns[stat] ?? const StatBreakdown(base: 0);
  }
}

class StatBreakdown {
  const StatBreakdown({
    required this.base,
    this.flat = 0,
    this.percent = 0,
    this.moreMultipliers = const [],
    this.lessMultipliers = const [],
  });

  final double base;
  final double flat;
  final double percent;
  final List<double> moreMultipliers;
  final List<double> lessMultipliers;

  double get finalValue {
    final withFlat = base + flat;
    final withPercent = withFlat * (1 + percent);
    final withMore = moreMultipliers.fold<double>(
      withPercent,
      (value, multiplier) => value * (1 + multiplier),
    );
    final withLess = lessMultipliers.fold<double>(
      withMore,
      (value, multiplier) => value * math.max(0, 1 - multiplier),
    );

    if (!withLess.isFinite) {
      return 0;
    }

    return withLess;
  }

  StatBreakdown apply(StatModifier modifier) {
    switch (modifier.type) {
      case StatModifierType.flat:
        return copyWith(flat: flat + modifier.value);
      case StatModifierType.percent:
        return copyWith(percent: percent + modifier.value);
      case StatModifierType.more:
        return copyWith(
          moreMultipliers: [...moreMultipliers, modifier.value],
        );
      case StatModifierType.less:
        return copyWith(
          lessMultipliers: [...lessMultipliers, modifier.value],
        );
    }
  }

  StatBreakdown copyWith({
    double? flat,
    double? percent,
    List<double>? moreMultipliers,
    List<double>? lessMultipliers,
  }) {
    return StatBreakdown(
      base: base,
      flat: flat ?? this.flat,
      percent: percent ?? this.percent,
      moreMultipliers: moreMultipliers ?? this.moreMultipliers,
      lessMultipliers: lessMultipliers ?? this.lessMultipliers,
    );
  }
}

class StatModifier {
  const StatModifier({
    required this.stat,
    required this.type,
    required this.value,
    required this.source,
  });

  const StatModifier.flat({
    required this.stat,
    required this.value,
    required this.source,
  }) : type = StatModifierType.flat;

  const StatModifier.percent({
    required this.stat,
    required this.value,
    required this.source,
  }) : type = StatModifierType.percent;

  const StatModifier.more({
    required this.stat,
    required this.value,
    required this.source,
  }) : type = StatModifierType.more;

  const StatModifier.less({
    required this.stat,
    required this.value,
    required this.source,
  }) : type = StatModifierType.less;

  final StatKey stat;
  final StatModifierType type;
  final double value;
  final String source;
}

enum StatModifierType { flat, percent, more, less }

enum StatKey { hp, attack, armor }
