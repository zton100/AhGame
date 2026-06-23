class QualityConfig {
  const QualityConfig({
    required this.id,
    required this.name,
    required this.affixMin,
    required this.affixMax,
    required this.statMultiplier,
    required this.specialEffectChance,
  });

  factory QualityConfig.fromJson(Map<String, Object?> json) {
    return QualityConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      affixMin: json['affixMin'] as int,
      affixMax: json['affixMax'] as int,
      statMultiplier: (json['statMultiplier'] as num).toDouble(),
      specialEffectChance: (json['specialEffectChance'] as num).toDouble(),
    );
  }

  final String id;
  final String name;
  final int affixMin;
  final int affixMax;
  final double statMultiplier;
  final double specialEffectChance;
}
