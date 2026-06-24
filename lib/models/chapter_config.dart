import 'inventory_state.dart';

class ChapterConfig {
  const ChapterConfig({
    required this.chapterId,
    required this.name,
    required this.stages,
  });

  factory ChapterConfig.fromJson(Map<String, Object?> json) {
    return ChapterConfig(
      chapterId: json['chapterId'] as String? ?? json['id'] as String,
      name: json['name'] as String,
      stages: [
        for (final stage in json['stages'] as List? ?? const [])
          StageConfig.fromJson(Map<String, Object?>.from(stage as Map)),
      ],
    );
  }

  final String chapterId;
  final String name;
  final List<StageConfig> stages;
}

class StageConfig {
  const StageConfig({
    required this.stageId,
    required this.stageName,
    required this.monsterIds,
    required this.requiredLevel,
    this.firstClearRewards,
    this.isBossStage = false,
  });

  factory StageConfig.fromJson(Map<String, Object?> json) {
    return StageConfig(
      stageId: json['stageId'] as String,
      stageName: json['stageName'] as String,
      monsterIds: List<String>.from(json['monsterIds'] as List? ?? const []),
      requiredLevel: json['requiredLevel'] as int? ?? 1,
      firstClearRewards: json['firstClearRewards'] is Map
          ? StageFirstClearRewards.fromJson(
              Map<String, Object?>.from(json['firstClearRewards'] as Map),
            )
          : null,
      isBossStage: json['isBossStage'] as bool? ?? false,
    );
  }

  final String stageId;
  final String stageName;
  final List<String> monsterIds;
  final int requiredLevel;
  final StageFirstClearRewards? firstClearRewards;
  final bool isBossStage;
}

class StageFirstClearRewards {
  const StageFirstClearRewards({
    this.experience = 0,
    this.gold = 0,
    this.materials = const [],
  });

  factory StageFirstClearRewards.fromJson(Map<String, Object?> json) {
    return StageFirstClearRewards(
      experience: json['experience'] as int? ?? 0,
      gold: json['gold'] as int? ?? 0,
      materials: [
        for (final material in json['materials'] as List? ?? const [])
          MaterialStack.fromJson(Map<String, Object?>.from(material as Map)),
      ],
    );
  }

  final int experience;
  final int gold;
  final List<MaterialStack> materials;
}
