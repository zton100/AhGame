import 'dart:math' as math;

import '../../models/battle_state.dart';
import '../../models/character_state.dart';
import '../../models/monster_runtime.dart';
import '../../models/skill_loadout.dart';
import '../skills/skill_effect_preview_service.dart';
import '../skills/skill_runtime.dart';
import '../skills/skill_service.dart';
import '../stats/stat_aggregation_service.dart';

class BattleSimulator {
  const BattleSimulator({
    SkillEffectPreviewService previewService =
        const SkillEffectPreviewService(),
  }) : _previewService = previewService;

  final SkillEffectPreviewService _previewService;

  BattleState createBattle({
    required CharacterState character,
    required ComputedStats computedStats,
    required SkillLoadout skillLoadout,
    required MonsterRuntime monster,
    required SkillService skillService,
    Map<String, int> skillLevels = const {},
    String? battleId,
  }) {
    final skillRuntimes = [
      for (final skillId in skillLoadout.activeSkillIds)
        SkillRuntime.ready(
          skillId: skillId,
          currentCooldown: skillService.requireSkill(skillId).cooldown,
        ),
    ];
    final skillConfigs = {
      for (final skillId in skillLoadout.activeSkillIds)
        skillId: skillService.requireSkill(skillId),
    };
    final id =
        battleId ?? 'battle_${character.classConfig.id}_${monster.monsterId}';

    return BattleState(
      battleId: id,
      characterClassId: character.classConfig.id,
      characterStats: computedStats,
      skillRuntimes: skillRuntimes,
      skillConfigs: skillConfigs,
      skillLevels: skillLevels,
      monster: monster,
      elapsedSeconds: 0,
      playerMaxHp: _safePositive(computedStats.finalStats.hp, fallback: 100),
      playerCurrentHp:
          _safePositive(computedStats.finalStats.hp, fallback: 100),
      playerArmor: math.max(0, computedStats.finalStats.armor),
      monsterAttackCooldownRemaining: 2,
      monsterAttackInterval: 2,
      logs: [
        BattleLogEntry(
          time: 0,
          type: BattleLogType.battleStarted,
          message:
              '战斗开始：${character.classConfig.name} 对阵 ${_monsterLabel(monster.monsterId)}。',
          metadata: {
            'characterClassId': character.classConfig.id,
            'monsterId': monster.monsterId,
          },
        ),
      ],
    );
  }

  BattleState tick(
    BattleState state,
    double seconds,
  ) {
    if (seconds < 0) {
      throw ArgumentError.value(seconds, 'seconds', 'Cannot tick backwards.');
    }
    if (state.isFinished || seconds == 0) {
      return state;
    }

    final nextTime = state.elapsedSeconds + seconds;
    var monster = state.monster;
    var playerCurrentHp = state.playerCurrentHp;
    var monsterAttackCooldown = state.monsterAttackCooldownRemaining - seconds;
    final logs = [...state.logs];
    var skillRuntimes = [
      for (final runtime in state.skillRuntimes) runtime.tickCooldown(seconds),
    ];

    final castIndex = skillRuntimes.indexWhere((runtime) => runtime.canCast);
    if (castIndex >= 0) {
      final runtime = skillRuntimes[castIndex];
      final skill = state.skillConfigs[runtime.skillId];
      if (skill == null) {
        throw StateError('Skill config not found: ${runtime.skillId}');
      }
      final rawDamage = _previewService
          .previewDamage(
            skill: skill,
            stats: state.characterStats,
            skillLevel: state.skillLevels[runtime.skillId] ?? 1,
          )
          .damage;
      final damage = _damageAfterArmor(
        rawDamage: rawDamage,
        armor: monster.armor,
      );
      logs.add(BattleLogEntry(
        time: nextTime,
        type: BattleLogType.skillCast,
        message: '释放技能：${skill.name}。',
        metadata: {'skillId': skill.id},
      ));
      final result = _applyDamage(
        monster: monster,
        rawDamage: rawDamage,
        finalDamage: damage,
        time: nextTime,
        logs: logs,
        source: skill.name,
      );
      monster = result.monster;
      skillRuntimes = [
        for (var i = 0; i < skillRuntimes.length; i += 1)
          if (i == castIndex) runtime.cast() else skillRuntimes[i],
      ];
    } else {
      final rawDamage = state.characterStats.finalStats.attack;
      final damage = _damageAfterArmor(
        rawDamage: rawDamage,
        armor: monster.armor,
      );
      logs.add(BattleLogEntry(
        time: nextTime,
        type: BattleLogType.basicAttack,
        message: '普通攻击。',
        metadata: {'multiplier': 1.0},
      ));
      final result = _applyDamage(
        monster: monster,
        rawDamage: rawDamage,
        finalDamage: damage,
        time: nextTime,
        logs: logs,
        source: '普通攻击',
      );
      monster = result.monster;
    }

    if (!monster.isAlive) {
      logs.add(BattleLogEntry(
        time: nextTime,
        type: BattleLogType.monsterDeath,
        message: '${_monsterLabel(monster.monsterId)} 已死亡。',
        metadata: {'monsterId': monster.monsterId},
      ));
      logs.add(BattleLogEntry(
        time: nextTime,
        type: BattleLogType.victory,
        message: '战斗胜利。',
        metadata: {'battleId': state.battleId},
      ));
      return state.copyWith(
        skillRuntimes: skillRuntimes,
        monster: monster,
        elapsedSeconds: nextTime,
        logs: logs,
        result: BattleResult.victory,
      );
    }

    if (monsterAttackCooldown <= 0) {
      final result = _applyMonsterAttack(
        monster: monster,
        playerCurrentHp: playerCurrentHp,
        playerMaxHp: state.playerMaxHp,
        playerArmor: state.playerArmor,
        time: nextTime,
        logs: logs,
      );
      playerCurrentHp = result.playerCurrentHp;
      monsterAttackCooldown = state.monsterAttackInterval;

      if (playerCurrentHp <= 0) {
        logs.add(BattleLogEntry(
          time: nextTime,
          type: BattleLogType.playerDeath,
          message: '玩家被击败。',
          metadata: {'battleId': state.battleId},
        ));
        logs.add(BattleLogEntry(
          time: nextTime,
          type: BattleLogType.defeat,
          message: '战斗失败。',
          metadata: {'battleId': state.battleId},
        ));
        return state.copyWith(
          skillRuntimes: skillRuntimes,
          monster: monster,
          elapsedSeconds: nextTime,
          logs: logs,
          playerCurrentHp: 0,
          monsterAttackCooldownRemaining: monsterAttackCooldown,
          result: BattleResult.defeat,
        );
      }
    }

    return state.copyWith(
      skillRuntimes: skillRuntimes,
      monster: monster,
      elapsedSeconds: nextTime,
      logs: logs,
      playerCurrentHp: playerCurrentHp,
      monsterAttackCooldownRemaining: monsterAttackCooldown,
    );
  }

  double _damageAfterArmor({
    required double rawDamage,
    required double armor,
  }) {
    final reduction = 100 / (100 + math.max(0, armor));
    final finalDamage = rawDamage * reduction;
    if (!finalDamage.isFinite) {
      return 1;
    }
    return math.max(1, finalDamage);
  }

  _DamageApplication _applyDamage({
    required MonsterRuntime monster,
    required double rawDamage,
    required double finalDamage,
    required double time,
    required List<BattleLogEntry> logs,
    required String source,
  }) {
    final damagedMonster = monster.takeDamage(finalDamage);
    logs.add(BattleLogEntry(
      time: time,
      type: BattleLogType.damage,
      message: '$source 造成 ${finalDamage.toStringAsFixed(1)} 点伤害。',
      metadata: {
        'source': source,
        'rawDamage': rawDamage,
        'finalDamage': finalDamage,
      },
    ));
    logs.add(BattleLogEntry(
      time: time,
      type: BattleLogType.monsterHp,
      message:
          '${_monsterLabel(damagedMonster.monsterId)} 生命 ${damagedMonster.currentHp.toStringAsFixed(1)}/${damagedMonster.maxHp.toStringAsFixed(1)}。',
      metadata: {
        'monsterId': damagedMonster.monsterId,
        'currentHp': damagedMonster.currentHp,
        'maxHp': damagedMonster.maxHp,
      },
    ));
    return _DamageApplication(monster: damagedMonster);
  }

  _MonsterAttackApplication _applyMonsterAttack({
    required MonsterRuntime monster,
    required double playerCurrentHp,
    required double playerMaxHp,
    required double playerArmor,
    required double time,
    required List<BattleLogEntry> logs,
  }) {
    if (monster.attack <= 0) {
      logs.add(BattleLogEntry(
        time: time,
        type: BattleLogType.monsterAttack,
        message: '${_monsterLabel(monster.monsterId)} 发起攻击，但没有造成伤害。',
        metadata: {'monsterAttack': monster.attack, 'finalDamage': 0},
      ));
      return _MonsterAttackApplication(playerCurrentHp: playerCurrentHp);
    }

    final damage = _damageAfterArmor(
      rawDamage: monster.attack,
      armor: playerArmor,
    );
    final nextHp = math.max(0, playerCurrentHp - damage).toDouble();
    logs.add(BattleLogEntry(
      time: time,
      type: BattleLogType.monsterAttack,
      message:
          '${_monsterLabel(monster.monsterId)} 攻击玩家，造成 ${damage.toStringAsFixed(1)} 点伤害。',
      metadata: {
        'monsterId': monster.monsterId,
        'rawDamage': monster.attack,
        'finalDamage': damage,
      },
    ));
    logs.add(BattleLogEntry(
      time: time,
      type: BattleLogType.playerHp,
      message:
          '玩家生命：${nextHp.toStringAsFixed(1)} / ${playerMaxHp.toStringAsFixed(1)}。',
      metadata: {
        'currentHp': nextHp,
        'maxHp': playerMaxHp,
      },
    ));

    return _MonsterAttackApplication(playerCurrentHp: nextHp);
  }

  double _safePositive(double value, {required double fallback}) {
    if (!value.isFinite || value <= 0) {
      return fallback;
    }

    return value;
  }
}

String _monsterLabel(String monsterId) {
  switch (monsterId) {
    case 'skeleton_grunt':
      return '亡骨杂兵';
    case 'plague_rat':
      return '瘟疫鼠';
    case 'blood_cultist':
      return '血月信徒';
    case 'abyss_imp':
      return '深渊小鬼';
    case 'training_dummy':
      return '训练假人';
    case 'grave_guardian':
      return '亡骨守门人';
    case 'plague_carrier':
      return '瘟疫携带者';
    case 'blood_acolyte':
      return '血月侍僧';
    case 'ash_wraith':
      return '灰烬残魂';
    case 'frost_bone_archer':
      return '霜骨弓手';
    case 'relic_gatekeeper':
      return '遗装守门人';
    case 'plague_acolyte':
      return '瘟疫侍僧';
    case 'blood_incense_priest':
      return '血香祭司';
    case 'rotting_reliquary_guard':
      return '腐化圣匣卫士';
    case 'fallen_sanctifier':
      return '腐化圣裁者';
    case 'plague_bell_keeper':
      return '瘟疫钟守卫';
  }
  return monsterId;
}

class _DamageApplication {
  const _DamageApplication({required this.monster});

  final MonsterRuntime monster;
}

class _MonsterAttackApplication {
  const _MonsterAttackApplication({required this.playerCurrentHp});

  final double playerCurrentHp;
}
