import '../../models/skill_config.dart';
import '../stats/stat_aggregation_service.dart';

class SkillEffectPreviewService {
  const SkillEffectPreviewService();

  SkillEffectPreview previewDamage({
    required SkillConfig skill,
    required ComputedStats stats,
    int skillLevel = 1,
  }) {
    var directDamage = 0.0;
    final levelMultiplier = _levelMultiplier(skillLevel);

    for (final effect in skill.effects) {
      if (!effect.isDirectDamage) {
        continue;
      }

      directDamage +=
          stats.finalStats.attack * effect.damageMultiplier * levelMultiplier;
    }

    return SkillEffectPreview(
      skillId: skill.id,
      damage: directDamage,
    );
  }

  double _levelMultiplier(int skillLevel) {
    final normalizedLevel = skillLevel < 1 ? 1 : skillLevel;
    return 1 + (normalizedLevel - 1) * 0.08;
  }
}

class SkillEffectPreview {
  const SkillEffectPreview({
    required this.skillId,
    required this.damage,
  });

  final String skillId;
  final double damage;
}
