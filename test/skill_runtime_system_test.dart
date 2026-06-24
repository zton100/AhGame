import 'package:abyss_relic/models/data_file_meta.dart';
import 'package:abyss_relic/models/loaded_data_file.dart';
import 'package:abyss_relic/models/save_data.dart';
import 'package:abyss_relic/models/skill_config.dart';
import 'package:abyss_relic/models/skill_loadout.dart';
import 'package:abyss_relic/models/stat_block.dart';
import 'package:abyss_relic/systems/config/game_database.dart';
import 'package:abyss_relic/systems/save/save_migration_service.dart';
import 'package:abyss_relic/systems/skills/skill_effect_preview_service.dart';
import 'package:abyss_relic/systems/skills/skill_runtime.dart';
import 'package:abyss_relic/systems/skills/skill_service.dart';
import 'package:abyss_relic/systems/stats/stat_aggregation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SkillConfig parses skill records from skills.json shape', () {
    final skill = SkillConfig.fromJson(_toxicSlashRecord());

    expect(skill.id, 'toxic_slash');
    expect(skill.classId, 'exile');
    expect(skill.skillType, 'active');
    expect(skill.cooldown, 3);
    expect(skill.tags, containsAll(['poison', 'shadow']));
    expect(skill.effects.single.effectId, 'deal_damage');
    expect(skill.effects.single.damageMultiplier, 1.2);
    expect(skill.effects.single.isDirectDamage, isTrue);
  });

  test('SkillService limits skills to their allowed class', () {
    final service = SkillService(_database());

    expect(service.skillsForClass('exile').map((skill) => skill.id), [
      'toxic_slash',
    ]);
    expect(
      service.validateSkillForClass(
        skillId: 'toxic_slash',
        classId: 'exile',
      ),
      isTrue,
    );
    expect(
      service.validateSkillForClass(
        skillId: 'ember_bolt',
        classId: 'exile',
      ),
      isFalse,
    );
  });

  test('SkillService finds skills by tag', () {
    final service = SkillService(_database());

    expect(service.skillsByTag('fire').map((skill) => skill.id), [
      'ember_bolt',
    ]);
  });

  test('SkillRuntime ticks cooldown down to zero', () {
    final runtime = const SkillRuntime(
      skillId: 'toxic_slash',
      cooldownRemaining: 3,
      currentCooldown: 3,
    );

    final afterPartialTick = runtime.tickCooldown(1.25);
    final afterFullTick = afterPartialTick.tickCooldown(10);

    expect(afterPartialTick.cooldownRemaining, 1.75);
    expect(afterPartialTick.canCast, isFalse);
    expect(afterFullTick.cooldownRemaining, 0);
    expect(afterFullTick.canCast, isTrue);
  });

  test('SkillRuntime enters cooldown after cast', () {
    const runtime = SkillRuntime.ready(
      skillId: 'toxic_slash',
      currentCooldown: 3,
    );

    final casted = runtime.cast();

    expect(casted.cooldownRemaining, 3);
    expect(casted.canCast, isFalse);
    expect(() => casted.cast(), throwsStateError);
  });

  test('SkillLoadout supports JSON round trip and slot count validation', () {
    final loadout = SkillLoadout(
      activeSkillIds: ['toxic_slash', 'shadow_step'],
      passiveSkillIds: ['poison_training'],
      ultimateSkillId: 'abyss_judgement',
    );

    final restored = SkillLoadout.fromJson(loadout.toJson());

    expect(restored.activeSkillIds, ['toxic_slash', 'shadow_step']);
    expect(restored.passiveSkillIds, ['poison_training']);
    expect(restored.ultimateSkillId, 'abyss_judgement');
    expect(
      () => SkillLoadout.fromJson({
        'activeSkillIds': ['a', 'b', 'c', 'd'],
      }),
      throwsFormatException,
    );
  });

  test('legacy saves without skill loadout default to current class skill', () {
    final save = SaveData.fromJson({
      'saveVersion': SaveData.currentVersion,
      'createdAt': '2026-06-24T00:00:00.000Z',
      'lastSavedAt': '2026-06-24T00:10:00.000Z',
      'lastExitAt': null,
      'playerProgress': {
        'currentClassId': 'ember_mage',
        'level': 3,
        'experience': 120,
      },
      'inventory': {
        'equipmentInstanceIds': <String>[],
      },
      'settings': {
        'soundEnabled': true,
        'hapticsEnabled': true,
      },
    });

    expect(save.playerProgress.skillLoadout.activeSkillIds, ['ember_bolt']);
  });

  test('migration keeps old saves compatible with default skill loadout', () {
    final result = const SaveMigrationService().migrate({
      'saveVersion': 1,
      'createdAt': '2026-06-23T00:00:00.000Z',
      'lastSavedAt': '2026-06-23T00:10:00.000Z',
      'playerProgress': {
        'currentClassId': 'exile',
        'level': 3,
        'experience': 120,
      },
      'inventory': {
        'equipmentInstanceIds': <String>[],
      },
    });

    expect(result.saveData.playerProgress.skillLoadout.activeSkillIds, [
      'toxic_slash',
    ]);
  });

  test('skill preview damage increases as attack increases', () {
    final service = const SkillEffectPreviewService();
    final skill = SkillConfig.fromJson(_toxicSlashRecord());
    final lowStats = const StatAggregationService().compute(
      base: const StatBlock(hp: 100, attack: 10, armor: 5),
    );
    final highStats = const StatAggregationService().compute(
      base: const StatBlock(hp: 100, attack: 25, armor: 5),
    );

    final lowDamage = service.previewDamage(skill: skill, stats: lowStats);
    final highDamage = service.previewDamage(skill: skill, stats: highStats);

    expect(lowDamage.damage, 12);
    expect(highDamage.damage, greaterThan(lowDamage.damage));
  });
}

GameDatabase _database() {
  return GameDatabase.fromFiles([
    _file('assets/data/skills.json', {
      'schemaVersion': 1,
      'skills': [
        _toxicSlashRecord(),
        {
          'id': 'ember_bolt',
          'name': 'Ember Bolt',
          'classId': 'ember_mage',
          'skillType': 'active',
          'tags': ['fire'],
          'cooldown': 2.5,
          'effects': [
            {
              'effectId': 'deal_damage',
              'params': {'multiplier': 1.35, 'damageType': 'fire'},
            },
          ],
        },
      ],
    }),
  ]);
}

Map<String, Object?> _toxicSlashRecord() {
  return {
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
  };
}

LoadedDataFile _file(String assetPath, Map<String, Object?> json) {
  return LoadedDataFile(
    meta: DataFileMeta(
      assetPath: assetPath,
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      recordCount: 1,
      topLevelKeys: json.keys.toList(),
    ),
    json: json,
  );
}
