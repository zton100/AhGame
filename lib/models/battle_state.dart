import '../systems/stats/stat_aggregation_service.dart';
import 'monster_runtime.dart';
import 'skill_config.dart';
import '../systems/skills/skill_runtime.dart';

class BattleState {
  const BattleState({
    required this.battleId,
    required this.characterClassId,
    required this.characterStats,
    required this.skillRuntimes,
    required this.skillConfigs,
    required this.monster,
    required this.elapsedSeconds,
    required this.logs,
    this.result = BattleResult.running,
  });

  final String battleId;
  final String characterClassId;
  final ComputedStats characterStats;
  final List<SkillRuntime> skillRuntimes;
  final Map<String, SkillConfig> skillConfigs;
  final MonsterRuntime monster;
  final double elapsedSeconds;
  final List<BattleLogEntry> logs;
  final BattleResult result;

  bool get isFinished => result != BattleResult.running;

  BattleState copyWith({
    List<SkillRuntime>? skillRuntimes,
    Map<String, SkillConfig>? skillConfigs,
    MonsterRuntime? monster,
    double? elapsedSeconds,
    List<BattleLogEntry>? logs,
    BattleResult? result,
  }) {
    return BattleState(
      battleId: battleId,
      characterClassId: characterClassId,
      characterStats: characterStats,
      skillRuntimes: skillRuntimes ?? this.skillRuntimes,
      skillConfigs: skillConfigs ?? this.skillConfigs,
      monster: monster ?? this.monster,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      logs: logs ?? this.logs,
      result: result ?? this.result,
    );
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
}
