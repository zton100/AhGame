class SkillLoadout {
  factory SkillLoadout({
    List<String> activeSkillIds = const [],
    List<String> passiveSkillIds = const [],
    String? ultimateSkillId,
  }) {
    _validateCounts(
      activeSkillIds: activeSkillIds,
      passiveSkillIds: passiveSkillIds,
    );

    return SkillLoadout._(
      activeSkillIds: activeSkillIds,
      passiveSkillIds: passiveSkillIds,
      ultimateSkillId: ultimateSkillId,
    );
  }

  const SkillLoadout.empty()
      : activeSkillIds = const [],
        passiveSkillIds = const [],
        ultimateSkillId = null;

  const SkillLoadout._({
    required this.activeSkillIds,
    required this.passiveSkillIds,
    required this.ultimateSkillId,
  });

  factory SkillLoadout.defaultForClass(String classId) {
    final skillId = defaultActiveSkillIdForClass(classId);
    if (skillId == null) {
      return const SkillLoadout.empty();
    }

    return SkillLoadout(activeSkillIds: [skillId]);
  }

  factory SkillLoadout.validated({
    List<String> activeSkillIds = const [],
    List<String> passiveSkillIds = const [],
    String? ultimateSkillId,
  }) {
    _validateCounts(
      activeSkillIds: activeSkillIds,
      passiveSkillIds: passiveSkillIds,
    );

    return SkillLoadout(
        activeSkillIds: activeSkillIds,
        passiveSkillIds: passiveSkillIds,
        ultimateSkillId: ultimateSkillId);
  }

  factory SkillLoadout.fromJson(Map<String, Object?> json) {
    final activeSkillIds = List<String>.from(
      json['activeSkillIds'] as List? ?? const [],
    );
    final passiveSkillIds = List<String>.from(
      json['passiveSkillIds'] as List? ?? const [],
    );

    return SkillLoadout.validated(
      activeSkillIds: activeSkillIds,
      passiveSkillIds: passiveSkillIds,
      ultimateSkillId: json['ultimateSkillId'] as String?,
    );
  }

  static const int maxActiveSkills = 3;
  static const int maxPassiveSkills = 3;

  final List<String> activeSkillIds;
  final List<String> passiveSkillIds;
  final String? ultimateSkillId;

  Map<String, Object?> toJson() {
    return {
      'activeSkillIds': activeSkillIds,
      'passiveSkillIds': passiveSkillIds,
      'ultimateSkillId': ultimateSkillId,
    };
  }

  static String? defaultActiveSkillIdForClass(String classId) {
    switch (classId) {
      case 'exile':
        return 'toxic_slash';
      case 'necrospeaker':
        return 'bone_servant';
      case 'ember_mage':
        return 'ember_bolt';
      case 'frost_ranger':
        return 'frost_mark';
      case 'sanctifier':
        return 'judgement_strike';
      default:
        return null;
    }
  }

  static void _validateCounts({
    required List<String> activeSkillIds,
    required List<String> passiveSkillIds,
  }) {
    if (activeSkillIds.length > maxActiveSkills) {
      throw FormatException(
        'SkillLoadout activeSkillIds cannot exceed $maxActiveSkills.',
      );
    }

    if (passiveSkillIds.length > maxPassiveSkills) {
      throw FormatException(
        'SkillLoadout passiveSkillIds cannot exceed $maxPassiveSkills.',
      );
    }
  }
}
