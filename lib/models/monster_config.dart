import 'stat_block.dart';

class MonsterConfig {
  const MonsterConfig({
    required this.id,
    required this.name,
    required this.level,
    required this.tags,
    required this.baseStats,
    required this.rewards,
    required this.dropPoolId,
    this.skills = const [],
    this.resistances = const {},
  });

  factory MonsterConfig.fromJson(Map<String, Object?> json) {
    return MonsterConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      level: json['level'] as int,
      tags: List<String>.from(json['tags'] as List? ?? const []),
      baseStats: StatBlock.fromJson(
        Map<String, Object?>.from(json['baseStats'] as Map),
      ),
      rewards: MonsterRewards.fromJson(
        Map<String, Object?>.from(json['rewards'] as Map? ?? const {}),
      ),
      dropPoolId: json['dropPoolId'] as String,
      skills: List<String>.from(json['skills'] as List? ?? const []),
      resistances: {
        for (final entry in (json['resistances'] as Map? ?? const {}).entries)
          entry.key as String: (entry.value as num).toDouble(),
      },
    );
  }

  final String id;
  final String name;
  final int level;
  final List<String> tags;
  final StatBlock baseStats;
  final MonsterRewards rewards;
  final String dropPoolId;
  final List<String> skills;
  final Map<String, double> resistances;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'tags': tags,
      'baseStats': baseStats.toJson(),
      'rewards': rewards.toJson(),
      'dropPoolId': dropPoolId,
      'skills': skills,
      'resistances': resistances,
    };
  }
}

class MonsterRewards {
  const MonsterRewards({
    required this.experience,
    required this.gold,
    this.materials = const {},
  });

  factory MonsterRewards.fromJson(Map<String, Object?> json) {
    return MonsterRewards(
      experience: json['experience'] as int? ?? 0,
      gold: json['gold'] as int? ?? 0,
      materials: {
        for (final entry in (json['materials'] as Map? ?? const {}).entries)
          entry.key as String: entry.value as int,
      },
    );
  }

  final int experience;
  final int gold;
  final Map<String, int> materials;

  Map<String, Object?> toJson() {
    return {
      'experience': experience,
      'gold': gold,
      'materials': materials,
    };
  }
}
