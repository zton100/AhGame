import 'stat_block.dart';

class ClassConfig {
  const ClassConfig({
    required this.id,
    required this.name,
    required this.tags,
    required this.baseStats,
    required this.growth,
  });

  factory ClassConfig.fromJson(Map<String, Object?> json) {
    return ClassConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      tags: List<String>.from(json['tags'] as List? ?? const []),
      baseStats: StatBlock.fromJson(
        Map<String, Object?>.from(json['baseStats'] as Map),
      ),
      growth: StatBlock.fromJson(
        Map<String, Object?>.from(json['growth'] as Map),
      ),
    );
  }

  final String id;
  final String name;
  final List<String> tags;
  final StatBlock baseStats;
  final StatBlock growth;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'tags': tags,
      'baseStats': baseStats.toJson(),
      'growth': growth.toJson(),
    };
  }
}
