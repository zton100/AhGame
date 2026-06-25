import '../systems/stats/stat_aggregation_service.dart';
import 'monster_runtime.dart';
import 'skill_config.dart';
import 'stat_block.dart';
import '../systems/skills/skill_runtime.dart';

class BattleState {
  const BattleState({
    required this.battleId,
    required this.characterClassId,
    required this.characterStats,
    required this.skillRuntimes,
    required this.skillConfigs,
    this.skillLevels = const {},
    required this.monster,
    required this.elapsedSeconds,
    required this.logs,
    this.playerMaxHp = 100,
    this.playerCurrentHp = 100,
    this.playerArmor = 0,
    this.monsterAttackCooldownRemaining = 2,
    this.monsterAttackInterval = 2,
    this.result = BattleResult.running,
  });

  factory BattleState.fromJson(Map<String, Object?> json) {
    final finalStats = StatBlock.fromJson(
      Map<String, Object?>.from(json['characterStats'] as Map),
    );
    final skillConfigJson = Map<String, Object?>.from(
      json['skillConfigs'] as Map? ?? const {},
    );

    return BattleState(
      battleId: json['battleId'] as String,
      characterClassId: json['characterClassId'] as String,
      characterStats: const StatAggregationService().compute(base: finalStats),
      skillRuntimes: [
        for (final runtime in json['skillRuntimes'] as List? ?? const [])
          SkillRuntime.fromJson(Map<String, Object?>.from(runtime as Map)),
      ],
      skillConfigs: {
        for (final entry in skillConfigJson.entries)
          entry.key: SkillConfig.fromJson(
            Map<String, Object?>.from(entry.value as Map),
          ),
      },
      skillLevels: {
        for (final entry in (json['skillLevels'] as Map? ?? const {}).entries)
          entry.key as String: entry.value as int,
      },
      monster: MonsterRuntime.fromJson(
        Map<String, Object?>.from(json['monster'] as Map),
      ),
      elapsedSeconds: (json['elapsedSeconds'] as num).toDouble(),
      logs: [
        for (final log in json['logs'] as List? ?? const [])
          BattleLogEntry.fromJson(Map<String, Object?>.from(log as Map)),
      ],
      playerMaxHp: _optionalDouble(json, 'playerMaxHp', 100),
      playerCurrentHp: _optionalDouble(json, 'playerCurrentHp', 100),
      playerArmor: _optionalDouble(json, 'playerArmor', 0),
      monsterAttackCooldownRemaining: _optionalDouble(
        json,
        'monsterAttackCooldownRemaining',
        2,
      ),
      monsterAttackInterval: _optionalDouble(
        json,
        'monsterAttackInterval',
        2,
      ),
      result: BattleResult.values.byName(
        json['result'] as String? ?? BattleResult.running.name,
      ),
    );
  }

  final String battleId;
  final String characterClassId;
  final ComputedStats characterStats;
  final List<SkillRuntime> skillRuntimes;
  final Map<String, SkillConfig> skillConfigs;
  final Map<String, int> skillLevels;
  final MonsterRuntime monster;
  final double elapsedSeconds;
  final List<BattleLogEntry> logs;
  final double playerMaxHp;
  final double playerCurrentHp;
  final double playerArmor;
  final double monsterAttackCooldownRemaining;
  final double monsterAttackInterval;
  final BattleResult result;

  bool get isFinished => result != BattleResult.running;

  BattleState copyWith({
    List<SkillRuntime>? skillRuntimes,
    Map<String, SkillConfig>? skillConfigs,
    Map<String, int>? skillLevels,
    MonsterRuntime? monster,
    double? elapsedSeconds,
    List<BattleLogEntry>? logs,
    double? playerMaxHp,
    double? playerCurrentHp,
    double? playerArmor,
    double? monsterAttackCooldownRemaining,
    double? monsterAttackInterval,
    BattleResult? result,
  }) {
    return BattleState(
      battleId: battleId,
      characterClassId: characterClassId,
      characterStats: characterStats,
      skillRuntimes: skillRuntimes ?? this.skillRuntimes,
      skillConfigs: skillConfigs ?? this.skillConfigs,
      skillLevels: skillLevels ?? this.skillLevels,
      monster: monster ?? this.monster,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      logs: logs ?? this.logs,
      playerMaxHp: playerMaxHp ?? this.playerMaxHp,
      playerCurrentHp: playerCurrentHp ?? this.playerCurrentHp,
      playerArmor: playerArmor ?? this.playerArmor,
      monsterAttackCooldownRemaining:
          monsterAttackCooldownRemaining ?? this.monsterAttackCooldownRemaining,
      monsterAttackInterval:
          monsterAttackInterval ?? this.monsterAttackInterval,
      result: result ?? this.result,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'battleId': battleId,
      'characterClassId': characterClassId,
      'characterStats': characterStats.finalStats.toJson(),
      'skillRuntimes': [for (final runtime in skillRuntimes) runtime.toJson()],
      'skillConfigs': {
        for (final entry in skillConfigs.entries)
          entry.key: entry.value.toJson(),
      },
      'skillLevels': skillLevels,
      'monster': monster.toJson(),
      'elapsedSeconds': elapsedSeconds,
      'logs': [for (final log in logs) log.toJson()],
      'playerMaxHp': playerMaxHp,
      'playerCurrentHp': playerCurrentHp,
      'playerArmor': playerArmor,
      'monsterAttackCooldownRemaining': monsterAttackCooldownRemaining,
      'monsterAttackInterval': monsterAttackInterval,
      'result': result.name,
    };
  }
}

class BattleLogEntry {
  const BattleLogEntry({
    required this.time,
    required this.type,
    required this.message,
    this.metadata = const {},
  });

  final double time;
  final BattleLogType type;
  final String message;
  final Map<String, Object?> metadata;

  factory BattleLogEntry.fromJson(Map<String, Object?> json) {
    return BattleLogEntry(
      time: (json['time'] as num).toDouble(),
      type: BattleLogType.values.byName(json['type'] as String),
      message: json['message'] as String,
      metadata: Map<String, Object?>.from(json['metadata'] as Map? ?? const {}),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'time': time,
      'type': type.name,
      'message': message,
      'metadata': metadata,
    };
  }
}

enum BattleResult { running, victory, defeat }

enum BattleLogType {
  battleStarted,
  basicAttack,
  skillCast,
  damage,
  monsterHp,
  monsterDeath,
  victory,
  monsterCounter,
  monsterAttack,
  playerHp,
  playerDeath,
  defeat,
}

double _optionalDouble(
  Map<String, Object?> json,
  String fieldName,
  double fallback,
) {
  final value = json[fieldName];
  if (value == null) {
    return fallback;
  }
  if (value is num) {
    return value.toDouble();
  }

  throw FormatException('Expected $fieldName to be a number.');
}
