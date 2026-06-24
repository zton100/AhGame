class EnhancementConfig {
  const EnhancementConfig({
    required this.id,
    required this.maxLevel,
    required this.dustCostByLevel,
    required this.goldCostByLevel,
    required this.statMultiplierByLevel,
  });

  factory EnhancementConfig.fromJson(Map<String, Object?> json) {
    return EnhancementConfig(
      id: json['id'] as String,
      maxLevel: json['maxLevel'] as int,
      dustCostByLevel: List<int>.from(json['dustCostByLevel'] as List),
      goldCostByLevel: List<int>.from(json['goldCostByLevel'] as List),
      statMultiplierByLevel: [
        for (final value in json['statMultiplierByLevel'] as List)
          (value as num).toDouble(),
      ],
    );
  }

  final String id;
  final int maxLevel;
  final List<int> dustCostByLevel;
  final List<int> goldCostByLevel;
  final List<double> statMultiplierByLevel;

  EnhancementCost costForNextLevel(int currentLevel) {
    if (currentLevel < 0 || currentLevel >= maxLevel) {
      throw RangeError.range(currentLevel, 0, maxLevel - 1, 'currentLevel');
    }
    if (currentLevel >= dustCostByLevel.length ||
        currentLevel >= goldCostByLevel.length) {
      throw StateError('Enhancement cost table is shorter than maxLevel.');
    }

    return EnhancementCost(
      dust: dustCostByLevel[currentLevel],
      gold: goldCostByLevel[currentLevel],
    );
  }

  double multiplierForLevel(int level) {
    if (level <= 0) {
      return 1.0;
    }
    if (level > maxLevel || level > statMultiplierByLevel.length) {
      throw RangeError.range(level, 0, maxLevel, 'level');
    }

    return statMultiplierByLevel[level - 1];
  }
}

class EnhancementCost {
  const EnhancementCost({
    required this.dust,
    required this.gold,
  });

  final int dust;
  final int gold;
}
