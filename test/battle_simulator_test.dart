import 'package:abyss_relic/models/battle_state.dart';
import 'package:abyss_relic/models/character_state.dart';
import 'package:abyss_relic/models/class_config.dart';
import 'package:abyss_relic/models/data_file_meta.dart';
import 'package:abyss_relic/models/loaded_data_file.dart';
import 'package:abyss_relic/models/monster_runtime.dart';
import 'package:abyss_relic/models/skill_loadout.dart';
import 'package:abyss_relic/models/stat_block.dart';
import 'package:abyss_relic/systems/battle/battle_simulator.dart';
import 'package:abyss_relic/systems/config/game_database.dart';
import 'package:abyss_relic/systems/skills/skill_service.dart';
import 'package:abyss_relic/systems/stats/stat_aggregation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BattleSimulator creates a training dummy battle', () {
    final battle = _simulator().createBattle(
      character: _character(),
      computedStats: _stats(attack: 50),
      skillLoadout: SkillLoadout(activeSkillIds: ['toxic_slash']),
      monster: _trainingDummy(),
      skillService: _skillService(),
    );

    expect(battle.characterClassId, 'exile');
    expect(battle.monster.monsterId, 'training_dummy');
    expect(battle.result, BattleResult.running);
    expect(battle.isFinished, isFalse);
    expect(battle.playerMaxHp, 100);
    expect(battle.playerCurrentHp, 100);
    expect(battle.playerArmor, 6);
    expect(battle.skillRuntimes.single.skillId, 'toxic_slash');
    expect(battle.logs.single.type, BattleLogType.battleStarted);
  });

  test('BattleState JSON round trip preserves player survival fields', () {
    final battle = _createBattle(attack: 50).copyWith(
      playerCurrentHp: 42,
      monsterAttackCooldownRemaining: 1,
    );

    final restored = BattleState.fromJson(battle.toJson());

    expect(restored.battleId, battle.battleId);
    expect(restored.playerMaxHp, 100);
    expect(restored.playerCurrentHp, 42);
    expect(restored.playerArmor, 6);
    expect(restored.monsterAttackCooldownRemaining, 1);
    expect(restored.monsterAttackInterval, 2);
    expect(restored.skillRuntimes.single.skillId, 'toxic_slash');
  });

  test('tick casts an active skill, damages monster, and enters cooldown', () {
    final battle = _createBattle(attack: 50);

    final afterTick = _simulator().tick(battle, 1);

    expect(afterTick.elapsedSeconds, 1);
    expect(afterTick.monster.currentHp, lessThan(battle.monster.currentHp));
    expect(afterTick.skillRuntimes.single.cooldownRemaining, 3);
    expect(afterTick.logs.map((log) => log.type),
        contains(BattleLogType.skillCast));
    expect(
        afterTick.logs.map((log) => log.type), contains(BattleLogType.damage));
  });

  test('cooldown ticks down and skill can be cast again after it ends', () {
    final firstCast = _simulator().tick(_createBattle(attack: 20), 1);
    final coolingDown = _simulator().tick(firstCast, 2);
    final secondCast = _simulator().tick(coolingDown, 1);

    expect(coolingDown.skillRuntimes.single.cooldownRemaining, 1);
    expect(coolingDown.logs.where((log) => log.type == BattleLogType.skillCast),
        hasLength(1));
    expect(secondCast.skillRuntimes.single.cooldownRemaining, 3);
    expect(secondCast.logs.where((log) => log.type == BattleLogType.skillCast),
        hasLength(2));
  });

  test('normal attack is used when no active skill can be cast', () {
    final firstCast = _simulator().tick(_createBattle(attack: 20), 1);

    final secondTick = _simulator().tick(firstCast, 1);

    expect(secondTick.logs.map((log) => log.type),
        contains(BattleLogType.basicAttack));
    expect(secondTick.monster.currentHp, lessThan(firstCast.monster.currentHp));
  });

  test('monster death finishes battle with victory logs', () {
    var battle = _createBattle(attack: 120);

    for (var i = 0; i < 10 && !battle.isFinished; i += 1) {
      battle = _simulator().tick(battle, 1);
    }

    expect(battle.monster.isAlive, isFalse);
    expect(battle.result, BattleResult.victory);
    expect(battle.isFinished, isTrue);
    expect(
        battle.logs.map((log) => log.type), contains(BattleLogType.skillCast));
    expect(battle.logs.map((log) => log.type),
        contains(BattleLogType.monsterDeath));
    expect(battle.logs.map((log) => log.type), contains(BattleLogType.victory));
  });

  test('monster counterattack lowers player HP on cooldown', () {
    final battle = _simulator()
        .createBattle(
          character: _character(),
          computedStats: _stats(attack: 5, armor: 0),
          skillLoadout: SkillLoadout(activeSkillIds: ['toxic_slash']),
          monster: _aggressiveMonster(attack: 20),
          skillService: _skillService(),
        )
        .copyWith(monsterAttackCooldownRemaining: 0);

    final afterTick = _simulator().tick(battle, 1);

    expect(afterTick.playerCurrentHp, lessThan(battle.playerCurrentHp));
    expect(afterTick.playerCurrentHp, 80);
    expect(afterTick.logs.map((log) => log.type),
        contains(BattleLogType.monsterAttack));
    expect(afterTick.logs.map((log) => log.type),
        contains(BattleLogType.playerHp));
  });

  test('player HP does not go below zero and defeat finishes battle', () {
    final battle = _simulator()
        .createBattle(
          character: _character(),
          computedStats: _stats(attack: 1, hp: 10, armor: 0),
          skillLoadout: SkillLoadout(activeSkillIds: ['toxic_slash']),
          monster: _aggressiveMonster(attack: 999),
          skillService: _skillService(),
        )
        .copyWith(monsterAttackCooldownRemaining: 0);

    final afterTick = _simulator().tick(battle, 1);
    final afterFinishedTick = _simulator().tick(afterTick, 1);

    expect(afterTick.playerCurrentHp, 0);
    expect(afterTick.result, BattleResult.defeat);
    expect(afterTick.isFinished, isTrue);
    expect(afterFinishedTick, same(afterTick));
    expect(afterTick.logs.map((log) => log.type),
        contains(BattleLogType.playerDeath));
    expect(
        afterTick.logs.map((log) => log.type), contains(BattleLogType.defeat));
  });

  test('player armor reduces monster counterattack damage', () {
    final unarmored = _simulator().tick(
      _simulator()
          .createBattle(
            character: _character(),
            computedStats: _stats(attack: 5, armor: 0),
            skillLoadout: SkillLoadout(activeSkillIds: ['toxic_slash']),
            monster: _aggressiveMonster(attack: 50),
            skillService: _skillService(),
          )
          .copyWith(monsterAttackCooldownRemaining: 0),
      1,
    );
    final armored = _simulator().tick(
      _simulator()
          .createBattle(
            character: _character(),
            computedStats: _stats(attack: 5, armor: 100),
            skillLoadout: SkillLoadout(activeSkillIds: ['toxic_slash']),
            monster: _aggressiveMonster(attack: 50),
            skillService: _skillService(),
          )
          .copyWith(monsterAttackCooldownRemaining: 0),
      1,
    );

    expect(armored.playerCurrentHp, greaterThan(unarmored.playerCurrentHp));
  });
}

BattleState _createBattle({required double attack}) {
  return _simulator().createBattle(
    character: _character(),
    computedStats: _stats(attack: attack),
    skillLoadout: SkillLoadout(activeSkillIds: ['toxic_slash']),
    monster: _trainingDummy(),
    skillService: _skillService(),
  );
}

BattleSimulator _simulator() => const BattleSimulator();

CharacterState _character() {
  return const CharacterState(
    classConfig: ClassConfig(
      id: 'exile',
      name: 'Exile',
      tags: ['poison', 'shadow'],
      baseStats: StatBlock(hp: 100, attack: 18, armor: 6),
      growth: StatBlock(hp: 10, attack: 2, armor: 1),
    ),
    level: 1,
    experience: 0,
  );
}

ComputedStats _stats({
  required double attack,
  double hp = 100,
  double armor = 6,
}) {
  return const StatAggregationService().compute(
    base: StatBlock(hp: hp, attack: attack, armor: armor),
  );
}

MonsterRuntime _trainingDummy() {
  return const MonsterRuntime(
    monsterId: 'training_dummy',
    level: 1,
    maxHp: 200,
    currentHp: 200,
    attack: 0,
    armor: 0,
    tags: ['training', 'dummy'],
  );
}

MonsterRuntime _aggressiveMonster({required double attack}) {
  return MonsterRuntime(
    monsterId: 'skeleton_grunt',
    level: 1,
    maxHp: 500,
    currentHp: 500,
    attack: attack,
    armor: 0,
    tags: const ['undead'],
  );
}

SkillService _skillService() {
  return SkillService(
    GameDatabase.fromFiles([
      LoadedDataFile(
        meta: const DataFileMeta(
          assetPath: 'assets/data/skills.json',
          schemaVersion: 1,
          recordCount: 1,
          topLevelKeys: ['schemaVersion', 'skills'],
        ),
        json: {
          'schemaVersion': 1,
          'skills': [
            {
              'id': 'toxic_slash',
              'name': 'Toxic Slash',
              'classId': 'exile',
              'skillType': 'active',
              'tags': ['poison', 'shadow'],
              'cooldown': 3.0,
              'resourceCost': 10,
              'effects': [
                {
                  'effectId': 'deal_damage',
                  'params': {'multiplier': 1.2, 'damageType': 'poison'},
                },
              ],
            },
          ],
        },
      ),
    ]),
  );
}
