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
      monster: monster,
      elapsedSeconds: 0,
      logs: [
        BattleLogEntry(
          time: 0,
          type: BattleLogType.battleStarted,
          message:
              'Battle started: ${character.classConfig.id} vs ${monster.monsterId}.',
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
          .previewDamage(skill: skill, stats: state.characterStats)
          .damage;
      final damage = _damageAfterArmor(
        rawDamage: rawDamage,
        armor: monster.armor,
      );
      logs.add(BattleLogEntry(
        time: nextTime,
        type: BattleLogType.skillCast,
        message: '${skill.id} cast.',
        metadata: {'skillId': skill.id},
      ));
      final result = _applyDamage(
        monster: monster,
        rawDamage: rawDamage,
        finalDamage: damage,
        time: nextTime,
        logs: logs,
        source: skill.id,
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
        message: 'Basic attack.',
        metadata: {'multiplier': 1.0},
      ));
      final result = _applyDamage(
        monster: monster,
        rawDamage: rawDamage,
        finalDamage: damage,
        time: nextTime,
        logs: logs,
        source: 'basic_attack',
      );
      monster = result.monster;
    }

    if (!monster.isAlive) {
      logs.add(BattleLogEntry(
        time: nextTime,
        type: BattleLogType.monsterDeath,
        message: '${monster.monsterId} died.',
        metadata: {'monsterId': monster.monsterId},
      ));
      logs.add(BattleLogEntry(
        time: nextTime,
        type: BattleLogType.victory,
        message: 'Battle victory.',
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

    if (monster.attack > 0) {
      logs.add(BattleLogEntry(
        time: nextTime,
        type: BattleLogType.monsterCounter,
        message: '${monster.monsterId} prepares a counterattack.',
        metadata: {'monsterAttack': monster.attack},
      ));
    }

    return state.copyWith(
      skillRuntimes: skillRuntimes,
      monster: monster,
      elapsedSeconds: nextTime,
      logs: logs,
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
      message: '$source dealt ${finalDamage.toStringAsFixed(1)} damage.',
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
          '${damagedMonster.monsterId} hp ${damagedMonster.currentHp.toStringAsFixed(1)}/${damagedMonster.maxHp.toStringAsFixed(1)}.',
      metadata: {
        'monsterId': damagedMonster.monsterId,
        'currentHp': damagedMonster.currentHp,
        'maxHp': damagedMonster.maxHp,
      },
    ));
    return _DamageApplication(monster: damagedMonster);
  }
}

class _DamageApplication {
  const _DamageApplication({required this.monster});

  final MonsterRuntime monster;
}
