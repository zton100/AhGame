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
    expect(battle.skillRuntimes.single.skillId, 'toxic_slash');
    expect(battle.logs.single.type, BattleLogType.battleStarted);
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

ComputedStats _stats({required double attack}) {
  return const StatAggregationService().compute(
    base: StatBlock(hp: 100, attack: attack, armor: 6),
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
