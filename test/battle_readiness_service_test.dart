import 'package:abyss_relic/models/monster_runtime.dart';
import 'package:abyss_relic/models/auto_battle_run_state.dart';
import 'package:abyss_relic/models/stat_block.dart';
import 'package:abyss_relic/systems/battle/battle_readiness_service.dart';
import 'package:abyss_relic/systems/stats/stat_aggregation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('safe encounter is marked safe to attempt', () {
    final report = const BattleReadinessService().evaluate(
      characterStats: _stats(hp: 100, attack: 50, armor: 10),
      monster: _monster(hp: 80, attack: 5, armor: 0),
    );

    expect(report.safeToAttempt, isTrue);
    expect(report.reason, BattleReadinessReason.safe);
  });

  test('low damage encounter is marked unsafe', () {
    final report = const BattleReadinessService().evaluate(
      characterStats: _stats(hp: 100, attack: 1, armor: 0),
      monster: _monster(hp: 1000, attack: 0, armor: 0),
    );

    expect(report.safeToAttempt, isFalse);
    expect(report.reason, BattleReadinessReason.lowDamage);
  });

  test('high incoming damage encounter is marked unsafe', () {
    final report = const BattleReadinessService().evaluate(
      characterStats: _stats(hp: 40, attack: 20, armor: 0),
      monster: _monster(hp: 100, attack: 50, armor: 0),
    );

    expect(report.safeToAttempt, isFalse);
    expect(report.reason, BattleReadinessReason.lowSurvivability);
  });

  test('armor improves survivability estimate', () {
    final unsafe = const BattleReadinessService().evaluate(
      characterStats: _stats(hp: 100, attack: 20, armor: 0),
      monster: _monster(hp: 100, attack: 30, armor: 0),
    );
    final safer = const BattleReadinessService().evaluate(
      characterStats: _stats(hp: 100, attack: 20, armor: 100),
      monster: _monster(hp: 100, attack: 30, armor: 0),
    );

    expect(safer.estimatedIncomingDamage,
        lessThan(unsafe.estimatedIncomingDamage));
  });

  test('readiness reason maps to recommended next action', () {
    const service = BattleReadinessService();

    expect(
      service.recommendedActionFor(BattleReadinessReason.safe),
      AutoBattleRecommendedAction.continueProgression,
    );
    expect(
      service.recommendedActionFor(BattleReadinessReason.lowDamage),
      AutoBattleRecommendedAction.enhanceWeapon,
    );
    expect(
      service.recommendedActionFor(BattleReadinessReason.lowSurvivability),
      AutoBattleRecommendedAction.enhanceArmorOrHp,
    );
  });
}

ComputedStats _stats({
  required double hp,
  required double attack,
  required double armor,
}) {
  return const StatAggregationService().compute(
    base: StatBlock(hp: hp, attack: attack, armor: armor),
  );
}

MonsterRuntime _monster({
  required double hp,
  required double attack,
  required double armor,
}) {
  return MonsterRuntime(
    monsterId: 'test_monster',
    level: 1,
    maxHp: hp,
    currentHp: hp,
    attack: attack,
    armor: armor,
    tags: const ['test'],
  );
}
