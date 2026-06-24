import '../../models/skill_config.dart';
import '../config/game_database.dart';

class SkillService {
  SkillService(GameDatabase database)
      : _skillsById = {
          for (final entry in database.recordsForTable('skills').entries)
            entry.key: SkillConfig.fromJson(entry.value),
        };

  final Map<String, SkillConfig> _skillsById;

  SkillConfig requireSkill(String skillId) {
    final skill = _skillsById[skillId];
    if (skill == null) {
      throw StateError('Skill not found: $skillId');
    }

    return skill;
  }

  List<SkillConfig> skillsForClass(String classId) {
    return _sorted(
      _skillsById.values.where((skill) => _isSkillAllowedForClass(
            skill: skill,
            classId: classId,
          )),
    );
  }

  List<SkillConfig> skillsByTag(String tag) {
    return _sorted(
        _skillsById.values.where((skill) => skill.tags.contains(tag)));
  }

  bool validateSkillForClass({
    required String skillId,
    required String classId,
  }) {
    final skill = requireSkill(skillId);
    return _isSkillAllowedForClass(skill: skill, classId: classId);
  }

  static bool _isSkillAllowedForClass({
    required SkillConfig skill,
    required String classId,
  }) {
    return skill.classId == classId || skill.classId == 'all';
  }

  static List<SkillConfig> _sorted(Iterable<SkillConfig> skills) {
    return skills.toList()..sort((a, b) => a.id.compareTo(b.id));
  }
}
