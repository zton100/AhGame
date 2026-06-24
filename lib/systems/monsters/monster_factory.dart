import '../../models/monster_config.dart';
import '../../models/monster_runtime.dart';

class MonsterFactory {
  const MonsterFactory();

  MonsterRuntime create({
    required MonsterConfig config,
    int? level,
  }) {
    final runtimeLevel = level ?? config.level;
    final levelDelta = runtimeLevel - config.level;
    final maxHp = config.baseStats.hp * (1 + 0.12 * levelDelta);
    final attack = config.baseStats.attack * (1 + 0.10 * levelDelta);
    final armor = config.baseStats.armor * (1 + 0.08 * levelDelta);

    return MonsterRuntime(
      monsterId: config.id,
      level: runtimeLevel,
      maxHp: maxHp,
      currentHp: maxHp,
      attack: attack,
      armor: armor,
      tags: config.tags,
    );
  }
}
