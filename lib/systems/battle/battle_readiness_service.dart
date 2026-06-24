import 'dart:math' as math;

import '../../models/monster_runtime.dart';
import '../stats/stat_aggregation_service.dart';

class BattleReadinessService {
  const BattleReadinessService();

  BattleReadinessReport evaluate({
    required ComputedStats characterStats,
    required MonsterRuntime monster,
    int maxSeconds = 100,
  }) {
    final playerHp = _safePositive(characterStats.finalStats.hp, 100);
    final playerArmor = math.max(0, characterStats.finalStats.armor).toDouble();
    final playerAttack =
        math.max(1, characterStats.finalStats.attack).toDouble();

    final playerDamagePerSecond = _damageAfterArmor(
      rawDamage: playerAttack,
      armor: monster.armor,
    );
    final secondsToKill = monster.maxHp / playerDamagePerSecond;
    final monsterHitCount = math.max(0, (secondsToKill / 2).floor());
    final monsterDamagePerHit = monster.attack <= 0
        ? 0
        : _damageAfterArmor(rawDamage: monster.attack, armor: playerArmor);
    final expectedIncomingDamage =
        (monsterDamagePerHit * monsterHitCount).toDouble();
    final canKillInTime = secondsToKill <= maxSeconds;
    final canSurvive = expectedIncomingDamage < playerHp * 0.85;

    return BattleReadinessReport(
      safeToAttempt: canKillInTime && canSurvive,
      reason: canKillInTime
          ? canSurvive
              ? BattleReadinessReason.safe
              : BattleReadinessReason.lowSurvivability
          : BattleReadinessReason.lowDamage,
      estimatedSecondsToKill: secondsToKill,
      estimatedIncomingDamage: expectedIncomingDamage,
      playerEffectiveHp: playerHp,
      playerDamagePerSecond: playerDamagePerSecond,
      monsterDamagePerHit: monsterDamagePerHit.toDouble(),
    );
  }

  double _damageAfterArmor({
    required double rawDamage,
    required double armor,
  }) {
    final reduction = 100 / (100 + math.max(0, armor));
    final damage = rawDamage * reduction;
    if (!damage.isFinite) {
      return 1;
    }

    return math.max(1, damage);
  }

  double _safePositive(double value, double fallback) {
    if (!value.isFinite || value <= 0) {
      return fallback;
    }

    return value;
  }
}

class BattleReadinessReport {
  const BattleReadinessReport({
    required this.safeToAttempt,
    required this.reason,
    required this.estimatedSecondsToKill,
    required this.estimatedIncomingDamage,
    required this.playerEffectiveHp,
    required this.playerDamagePerSecond,
    required this.monsterDamagePerHit,
  });

  final bool safeToAttempt;
  final BattleReadinessReason reason;
  final double estimatedSecondsToKill;
  final double estimatedIncomingDamage;
  final double playerEffectiveHp;
  final double playerDamagePerSecond;
  final double monsterDamagePerHit;
}

enum BattleReadinessReason {
  safe,
  lowDamage,
  lowSurvivability,
}
