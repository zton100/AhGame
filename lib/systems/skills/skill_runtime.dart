import 'dart:math' as math;

class SkillRuntime {
  const SkillRuntime({
    required this.skillId,
    required this.cooldownRemaining,
    required this.currentCooldown,
  });

  const SkillRuntime.ready({
    required this.skillId,
    required this.currentCooldown,
  }) : cooldownRemaining = 0;

  final String skillId;
  final double cooldownRemaining;
  final double currentCooldown;

  bool get canCast => cooldownRemaining <= 0;

  SkillRuntime tickCooldown(double seconds) {
    if (seconds < 0) {
      throw ArgumentError.value(seconds, 'seconds', 'Cannot tick backwards.');
    }

    return copyWith(
      cooldownRemaining: math.max(0, cooldownRemaining - seconds),
    );
  }

  SkillRuntime cast() {
    if (!canCast) {
      throw StateError('Skill $skillId is still on cooldown.');
    }

    return copyWith(cooldownRemaining: currentCooldown);
  }

  SkillRuntime copyWith({
    double? cooldownRemaining,
    double? currentCooldown,
  }) {
    return SkillRuntime(
      skillId: skillId,
      cooldownRemaining: cooldownRemaining ?? this.cooldownRemaining,
      currentCooldown: currentCooldown ?? this.currentCooldown,
    );
  }
}
