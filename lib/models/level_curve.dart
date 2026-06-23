class LevelCurve {
  const LevelCurve({
    required this.id,
    required this.name,
    required this.maxLevel,
    required this.experienceToNext,
  });

  factory LevelCurve.fromJson(Map<String, Object?> json) {
    return LevelCurve(
      id: json['id'] as String,
      name: json['name'] as String,
      maxLevel: json['maxLevel'] as int,
      experienceToNext: List<int>.from(json['experienceToNext'] as List),
    );
  }

  final String id;
  final String name;
  final int maxLevel;
  final List<int> experienceToNext;

  int levelForTotalExperience(int totalExperience) {
    var level = 1;
    var requiredExperience = 0;

    for (final threshold in experienceToNext) {
      requiredExperience += threshold;
      if (totalExperience < requiredExperience || level >= maxLevel) {
        return level;
      }

      level += 1;
    }

    return maxLevel;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'maxLevel': maxLevel,
      'experienceToNext': experienceToNext,
    };
  }
}
