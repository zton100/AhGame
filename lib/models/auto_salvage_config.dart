class AutoSalvageConfig {
  const AutoSalvageConfig({
    this.enabled = false,
    this.minQualityToKeep = 'rare',
    this.keepLegendaryOrAbove = true,
    this.keepLocked = true,
    this.keepEquipped = true,
    this.minBuildMatchScoreToKeep = 60,
    this.allowedQualityIdsToSalvage = const [],
    this.maxInventoryUsageBeforeSalvage,
  });

  factory AutoSalvageConfig.fromJson(Map<String, Object?> json) {
    return AutoSalvageConfig(
      enabled: json['enabled'] as bool? ?? false,
      minQualityToKeep: json['minQualityToKeep'] as String? ?? 'rare',
      keepLegendaryOrAbove: json['keepLegendaryOrAbove'] as bool? ?? true,
      keepLocked: json['keepLocked'] as bool? ?? true,
      keepEquipped: json['keepEquipped'] as bool? ?? true,
      minBuildMatchScoreToKeep:
          (json['minBuildMatchScoreToKeep'] as num?)?.toDouble() ?? 60,
      allowedQualityIdsToSalvage: List<String>.from(
        json['allowedQualityIdsToSalvage'] as List? ?? const [],
      ),
      maxInventoryUsageBeforeSalvage:
          (json['maxInventoryUsageBeforeSalvage'] as num?)?.toDouble(),
    );
  }

  static const defaults = AutoSalvageConfig();

  final bool enabled;
  final String minQualityToKeep;
  final bool keepLegendaryOrAbove;
  final bool keepLocked;
  final bool keepEquipped;
  final double minBuildMatchScoreToKeep;
  final List<String> allowedQualityIdsToSalvage;
  final double? maxInventoryUsageBeforeSalvage;

  AutoSalvageConfig copyWith({
    bool? enabled,
    String? minQualityToKeep,
    bool? keepLegendaryOrAbove,
    bool? keepLocked,
    bool? keepEquipped,
    double? minBuildMatchScoreToKeep,
    List<String>? allowedQualityIdsToSalvage,
    double? maxInventoryUsageBeforeSalvage,
  }) {
    return AutoSalvageConfig(
      enabled: enabled ?? this.enabled,
      minQualityToKeep: minQualityToKeep ?? this.minQualityToKeep,
      keepLegendaryOrAbove: keepLegendaryOrAbove ?? this.keepLegendaryOrAbove,
      keepLocked: keepLocked ?? this.keepLocked,
      keepEquipped: keepEquipped ?? this.keepEquipped,
      minBuildMatchScoreToKeep:
          minBuildMatchScoreToKeep ?? this.minBuildMatchScoreToKeep,
      allowedQualityIdsToSalvage:
          allowedQualityIdsToSalvage ?? this.allowedQualityIdsToSalvage,
      maxInventoryUsageBeforeSalvage:
          maxInventoryUsageBeforeSalvage ?? this.maxInventoryUsageBeforeSalvage,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'enabled': enabled,
      'minQualityToKeep': minQualityToKeep,
      'keepLegendaryOrAbove': keepLegendaryOrAbove,
      'keepLocked': keepLocked,
      'keepEquipped': keepEquipped,
      'minBuildMatchScoreToKeep': minBuildMatchScoreToKeep,
      'allowedQualityIdsToSalvage': allowedQualityIdsToSalvage,
      'maxInventoryUsageBeforeSalvage': maxInventoryUsageBeforeSalvage,
    };
  }
}
