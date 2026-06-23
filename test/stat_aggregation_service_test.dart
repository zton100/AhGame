import 'package:abyss_relic/models/stat_block.dart';
import 'package:abyss_relic/systems/stats/stat_aggregation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('StatAggregationService applies flat then percent modifiers', () {
    const service = StatAggregationService();

    final result = service.compute(
      base: const StatBlock(hp: 100, attack: 50, armor: 10),
      modifiers: const [
        StatModifier.flat(stat: StatKey.attack, value: 100, source: 'weapon'),
        StatModifier.percent(
          stat: StatKey.attack,
          value: 0.10,
          source: 'class_tag',
        ),
      ],
    );

    expect(result.finalStats.attack, 165);
    expect(result.breakdownFor(StatKey.attack).flat, 100);
    expect(result.breakdownFor(StatKey.attack).percent, 0.10);
  });

  test('StatAggregationService multiplies more and less modifiers', () {
    const service = StatAggregationService();

    final result = service.compute(
      base: const StatBlock(hp: 100, attack: 100, armor: 10),
      modifiers: const [
        StatModifier.more(stat: StatKey.attack, value: 0.20, source: 'skill'),
        StatModifier.less(stat: StatKey.attack, value: 0.10, source: 'curse'),
      ],
    );

    expect(result.finalStats.attack, closeTo(108, 0.0001));
  });

  test('StatAggregationService allows negative modifiers without NaN', () {
    const service = StatAggregationService();

    final result = service.compute(
      base: const StatBlock(hp: 100, attack: 50, armor: 10),
      modifiers: const [
        StatModifier.percent(
            stat: StatKey.armor, value: -0.50, source: 'curse'),
        StatModifier.less(stat: StatKey.armor, value: 0.25, source: 'wound'),
      ],
    );

    expect(result.finalStats.armor.isNaN, isFalse);
    expect(result.finalStats.armor, 3.75);
  });
}
