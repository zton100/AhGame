import '../../models/skill_config.dart';
import '../stats/stat_aggregation_service.dart';

class SkillEffectPreviewService {
  const SkillEffectPreviewService();

  SkillEffectPreview previewDamage({
    required SkillConfig skill,
    required ComputedStats stats,
  }) {
    var directDamage = 0.0;

    for (final effect in skill.effects) {
      if (!effect.isDirectDamage) {
        continue;
      }

      directDamage += stats.finalStats.attack * effect.damageMultiplier;
    }

    return SkillEffectPreview(
      skillId: skill.id,
      damage: directDamage,
    );
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
