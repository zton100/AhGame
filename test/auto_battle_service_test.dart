import 'package:abyss_relic/models/auto_battle_run_state.dart';
import 'package:abyss_relic/models/auto_salvage_config.dart';
import 'package:abyss_relic/models/battle_state.dart';
import 'package:abyss_relic/models/data_file_meta.dart';
import 'package:abyss_relic/models/loaded_data_file.dart';
import 'package:abyss_relic/models/monster_runtime.dart';
import 'package:abyss_relic/models/save_data.dart';
import 'package:abyss_relic/systems/auto_battle/auto_battle_service.dart';
import 'package:abyss_relic/systems/battle/battle_readiness_service.dart';
import 'package:abyss_relic/systems/config/game_database.dart';
import 'package:abyss_relic/systems/stats/stat_aggregation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('runOneBattle grants experience', () async {
    SaveData? saved;

    final result = await _service(
      readinessService: const _AlwaysSafeReadinessService(),
    ).runOneBattle(
      saveData: SaveData.newGame(now: DateTime.utc(2026, 6, 24)),
      database: _database(),
      save: (saveData) async => saved = saveData,
    );

    expect(result.battlesCompleted, 1);
    expect(result.isRunning, isFalse);
    expect(result.stopReason, AutoBattleStopReason.maxBattlesReached);
    expect(result.totalExperience, 12);
    expect(result.saveData.playerProgress.experience, 12);
    expect(saved?.playerProgress.experience, 12);
  });

  test('runOneBattle stores generated equipment in the save', () async {
    final result = await _service(
      readinessService: const _AlwaysSafeReadinessService(),
    ).runOneBattle(
      saveData: SaveData.newGame(now: DateTime.utc(2026, 6, 24)),
      database: _database(),
      save: (_) async {},
    );

    expect(result.generatedEquipmentCount, 1);
    expect(result.saveData.inventory.equipmentInstanceIds, hasLength(1));
    final instanceId = result.saveData.inventory.equipmentInstanceIds.single;
    expect(result.saveData.inventory.equipmentInstances[instanceId]?.templateId,
        'rusted_blade');
  });

  test('runManyBattles accumulates rewards across battles', () async {
    var saveCount = 0;

    final result = await _service(
      readinessService: const _AlwaysSafeReadinessService(),
    ).runManyBattles(
      saveData: SaveData.newGame(now: DateTime.utc(2026, 6, 24)),
      database: _database(),
      maxBattles: 2,
      save: (_) async => saveCount += 1,
    );

    expect(result.battlesCompleted, 2);
    expect(saveCount, 2);
    expect(result.totalExperience, 21);
    expect(result.totalGold, 5);
    expect(result.totalMaterials['bone_shard'], 1);
    expect(result.saveData.playerProgress.currentStageId, '1-2');
    expect(result.stopReason, AutoBattleStopReason.chapterComplete);
  });

  test('runManyBattles stops when maxBattles is reached', () async {
    final result = await _service(
      readinessService: const _AlwaysSafeReadinessService(),
    ).runManyBattles(
      saveData: SaveData.newGame(now: DateTime.utc(2026, 6, 24)),
      database: _database(stageCount: 3),
      maxBattles: 2,
      save: (_) async {},
    );

    expect(result.battlesCompleted, 2);
    expect(result.stopReason, AutoBattleStopReason.maxBattlesReached);
    expect(result.saveData.playerProgress.currentStageId, '1-3');
  });

  test('current stage level too low farms highest cleared stage', () async {
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 24)).copyWith(
      playerProgress: SaveData.newGame().playerProgress.copyWith(
            currentStageId: '1-2',
            highestClearedStageId: '1-1',
          ),
    );

    final result = await _service(
      readinessService: const _AlwaysSafeReadinessService(),
    ).runOneBattle(
      saveData: save,
      database: _database(secondStageRequiredLevel: 99),
      save: (_) async {},
    );

    expect(result.battlesCompleted, 1);
    expect(result.totalExperience, 12);
    expect(result.generatedEquipmentCount, 1);
    expect(result.saveData.playerProgress.currentStageId, '1-2');
    expect(result.progressionStageId, '1-2');
    expect(result.farmingStageId, '1-1');
    expect(result.farmingBecauseLevelTooLow, isTrue);
    expect(result.stopReason, AutoBattleStopReason.maxBattlesReached);
  });

  test('level too low stops when no farmable stage exists', () async {
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 24)).copyWith(
      playerProgress: SaveData.newGame().playerProgress.copyWith(
            currentStageId: '1-2',
          ),
    );

    final result = await _service(
      readinessService: const _AlwaysSafeReadinessService(),
    ).runOneBattle(
      saveData: save,
      database: _database(secondStageRequiredLevel: 99),
      save: (_) async => fail('level too low should not save'),
    );

    expect(result.battlesCompleted, 0);
    expect(result.stopReason, AutoBattleStopReason.levelTooLow);
    expect(result.isRunning, isFalse);
  });

  test('farm battle level up lets the next battle return to progression',
      () async {
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 24)).copyWith(
      playerProgress: SaveData.newGame().playerProgress.copyWith(
            currentStageId: '1-2',
            highestClearedStageId: '1-1',
            experience: 95,
          ),
    );

    final result = await _service(
      readinessService: const _AlwaysSafeReadinessService(),
    ).runManyBattles(
      saveData: save,
      database: _database(secondStageRequiredLevel: 2),
      maxBattles: 2,
      save: (_) async {},
    );

    expect(result.battlesCompleted, 2);
    expect(result.saveData.playerProgress.level, 2);
    expect(result.saveData.playerProgress.currentStageId, '1-2');
    expect(result.progressionStageId, '1-2');
    expect(result.farmingStageId, isNull);
    expect(result.farmingBecauseLevelTooLow, isFalse);
    expect(result.stopReason, AutoBattleStopReason.chapterComplete);
  });

  test('final stage victory stops with chapterComplete', () async {
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 24)).copyWith(
      playerProgress: SaveData.newGame().playerProgress.copyWith(
            currentStageId: '1-2',
          ),
    );

    final result = await _service().runManyBattles(
      saveData: save,
      database: _database(),
      maxBattles: 10,
      save: (_) async {},
    );

    expect(result.battlesCompleted, 1);
    expect(result.stopReason, AutoBattleStopReason.chapterComplete);
    expect(result.saveData.playerProgress.currentStageId, '1-2');
  });

  test('full inventory rejects equipment without orphan instances', () async {
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 24)).copyWith(
      inventory: const InventorySave(
        equipmentInstanceIds: ['existing'],
        equipmentCapacity: 1,
      ),
    );

    final result = await _service().runOneBattle(
      saveData: save,
      database: _database(),
      save: (_) async {},
    );

    expect(result.rejectedEquipmentCount, 1);
    expect(result.generatedEquipmentCount, 0);
    expect(result.saveData.inventory.equipmentInstanceIds, ['existing']);
    expect(result.saveData.inventory.equipmentInstances, isEmpty);
  });

  test('runManyBattles accumulates auto salvaged equipment', () async {
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 24)).copyWith(
      inventory: const InventorySave(
        equipmentInstanceIds: [],
        autoSalvageConfig: AutoSalvageConfig(enabled: true),
      ),
    );

    final result = await _service().runManyBattles(
      saveData: save,
      database: _database(stageCount: 3, equipmentQualityPool: ['normal']),
      maxBattles: 2,
      save: (_) async {},
    );

    expect(result.battlesCompleted, 2);
    expect(result.autoSalvagedEquipmentCount, 2);
    expect(result.autoSalvageMaterials['salvage_dust'], 2);
    expect(result.saveData.inventory.equipmentInstanceIds, isEmpty);
    expect(result.saveData.inventory.equipmentInstances, isEmpty);
    expect(
      result.saveData.inventory.materials
          .where((material) => material.materialId == 'salvage_dust')
          .single
          .quantity,
      2,
    );
  });

  test('auto battle failure stops without rewards or stage progress', () async {
    var saved = false;
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 24));

    final result = await _service().runOneBattle(
      saveData: save,
      database: _database(
        classHp: 10,
        classAttack: 1,
        monsterHp: 500,
        monsterAttack: 999,
      ),
      save: (_) async => saved = true,
    );

    expect(result.stopReason, AutoBattleStopReason.battleFailed);
    expect(result.battlesCompleted, 0);
    expect(result.totalExperience, 0);
    expect(result.saveData.playerProgress.currentStageId, '1-1');
    expect(result.saveData.playerProgress.experience, 0);
    expect(saved, isFalse);
    expect(result.lastBattleLogs.map((log) => log.type),
        contains(BattleLogType.defeat));
  });

  test('runManyBattles stops when a battle fails', () async {
    final result = await _service().runManyBattles(
      saveData: SaveData.newGame(now: DateTime.utc(2026, 6, 24)),
      database: _database(
        stageCount: 3,
        classHp: 10,
        classAttack: 1,
        monsterHp: 500,
        monsterAttack: 999,
      ),
      maxBattles: 10,
      save: (_) async => fail('failed battles should not save rewards'),
    );

    expect(result.stopReason, AutoBattleStopReason.battleFailed);
    expect(result.battlesCompleted, 0);
    expect(result.saveData.playerProgress.currentStageId, '1-1');
  });

  test('unsafe progression farms highest cleared stage instead of stopping',
      () async {
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 24)).copyWith(
      playerProgress: SaveData.newGame().playerProgress.copyWith(
            currentStageId: '1-2',
            highestClearedStageId: '1-1',
          ),
    );

    final result = await _service().runOneBattle(
      saveData: save,
      database: _database(
        monsterHp: 20,
        monsterAttack: 0,
        secondMonsterHp: 500,
        secondMonsterAttack: 999,
      ),
      save: (_) async {},
    );

    expect(result.battlesCompleted, 1);
    expect(result.stopReason, AutoBattleStopReason.maxBattlesReached);
    expect(result.totalExperience, 12);
    expect(result.saveData.playerProgress.currentStageId, '1-2');
    expect(result.progressionStageId, '1-2');
    expect(result.farmingStageId, '1-1');
    expect(result.farmingBecauseUnsafe, isTrue);
    expect(result.farmingBecauseBattleFailed, isFalse);
    expect(result.lastBattleLogs.map((log) => log.message), contains('战斗胜利。'));
  });

  test('unsafe current stage farms highest cleared stage before attempting',
      () async {
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 24)).copyWith(
      playerProgress: SaveData.newGame().playerProgress.copyWith(
            currentStageId: '1-2',
            highestClearedStageId: '1-1',
          ),
    );

    final result = await _service().runOneBattle(
      saveData: save,
      database: _database(
        monsterHp: 20,
        monsterAttack: 0,
        secondMonsterHp: 500,
        secondMonsterAttack: 999,
      ),
      save: (_) async {},
    );

    expect(result.battlesCompleted, 1);
    expect(result.totalExperience, 12);
    expect(result.farmingStageId, '1-1');
    expect(result.farmingBecauseUnsafe, isTrue);
    expect(result.farmingBecauseBattleFailed, isFalse);
    expect(result.saveData.playerProgress.currentStageId, '1-2');
  });

  test('runManyBattles repeats unsafe progression fallback until max battles',
      () async {
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 24)).copyWith(
      playerProgress: SaveData.newGame().playerProgress.copyWith(
            currentStageId: '1-2',
            highestClearedStageId: '1-1',
          ),
    );

    final result = await _service().runManyBattles(
      saveData: save,
      database: _database(
        monsterHp: 20,
        monsterAttack: 0,
        secondMonsterHp: 500,
        secondMonsterAttack: 999,
      ),
      maxBattles: 2,
      save: (_) async {},
    );

    expect(result.battlesCompleted, 2);
    expect(result.totalExperience, 24);
    expect(result.saveData.playerProgress.currentStageId, '1-2');
    expect(result.farmingStageId, '1-1');
    expect(result.farmingBecauseUnsafe, isTrue);
    expect(result.farmingBecauseBattleFailed, isFalse);
    expect(result.stopReason, AutoBattleStopReason.maxBattlesReached);
  });
}

AutoBattleService _service({
  BattleReadinessService readinessService = const BattleReadinessService(),
}) {
  return AutoBattleService(readinessService: readinessService);
}

class _AlwaysSafeReadinessService extends BattleReadinessService {
  const _AlwaysSafeReadinessService();

  @override
  BattleReadinessReport evaluate({
    required ComputedStats characterStats,
    required MonsterRuntime monster,
    int maxSeconds = 100,
  }) {
    return const BattleReadinessReport(
      safeToAttempt: true,
      reason: BattleReadinessReason.safe,
      estimatedSecondsToKill: 1,
      estimatedIncomingDamage: 0,
      playerEffectiveHp: 100,
      playerDamagePerSecond: 100,
      monsterDamagePerHit: 0,
    );
  }
}

GameDatabase _database({
  int stageCount = 2,
  int secondStageRequiredLevel = 1,
  List<String> equipmentQualityPool = const ['rare'],
  num classHp = 100,
  num classAttack = 18,
  num classArmor = 6,
  num monsterHp = 85,
  num monsterAttack = 10,
  num secondMonsterHp = 55,
  num secondMonsterAttack = 8,
}) {
  return GameDatabase.fromFiles([
    _file('assets/data/classes.json', {
      'schemaVersion': 1,
      'classes': [
        {
          'id': 'exile',
          'name': 'Exile',
          'tags': ['poison'],
          'baseStats': {
            'hp': classHp,
            'attack': classAttack,
            'armor': classArmor
          },
          'growth': {'hp': 10, 'attack': 2, 'armor': 1},
        },
      ],
    }),
    _file('assets/data/skills.json', {
      'schemaVersion': 1,
      'skills': [
        {
          'id': 'toxic_slash',
          'name': 'Toxic Slash',
          'classId': 'exile',
          'skillType': 'active',
          'tags': ['poison'],
          'cooldown': 3.0,
          'resourceCost': 10,
          'effects': [
            {
              'effectId': 'direct_damage',
              'params': {'multiplier': 1.2, 'damageType': 'poison'},
            },
          ],
        },
      ],
    }),
    _file('assets/data/monsters.json', {
      'schemaVersion': 1,
      'monsters': [
        _monster(
          'skeleton_grunt',
          'Skeleton Grunt',
          monsterHp,
          monsterAttack,
          4,
          12,
          3,
          {'bone_shard': 1},
        ),
        _monster(
          'plague_rat',
          'Plague Rat',
          secondMonsterHp,
          secondMonsterAttack,
          1,
          9,
          2,
          {},
        ),
      ],
    }),
    _file('assets/data/chapters.json', {
      'schemaVersion': 1,
      'chapters': [
        {
          'id': 'chapter_1',
          'chapterId': 'chapter_1',
          'name': 'Chapter 1',
          'stages': [
            _stage('1-1', 'Grave Road', 'skeleton_grunt', 1),
            if (stageCount >= 2)
              _stage(
                '1-2',
                'Rat Cellar',
                'plague_rat',
                secondStageRequiredLevel,
                isBoss: stageCount == 2,
              ),
            if (stageCount >= 3)
              _stage('1-3', 'Bone Gate', 'skeleton_grunt', 1, isBoss: true),
          ],
        },
      ],
    }),
    _file('assets/data/level_curves.json', {
      'schemaVersion': 1,
      'level_curves': [
        {
          'id': 'default',
          'name': 'Default',
          'maxLevel': 3,
          'experienceToNext': [100, 140],
        },
      ],
    }),
    _file('assets/data/drop_pools.json', {
      'schemaVersion': 1,
      'drop_pools': [
        {
          'id': 'drop_equipment',
          'name': 'Equipment Drop',
          'entries': [
            {
              'type': 'equipment',
              'refId': 'rusted_blade',
              'weight': 100,
              'minQty': 1,
              'maxQty': 1,
            },
          ],
        },
      ],
    }),
    _file('assets/data/equipment_templates.json', {
      'schemaVersion': 1,
      'equipment_templates': [
        {
          'id': 'rusted_blade',
          'name': 'Rusted Blade',
          'slot': 'main_weapon',
          'allowedClasses': ['exile'],
          'minLevel': 1,
          'qualityPool': equipmentQualityPool,
          'baseStats': [
            {'stat': 'attack', 'min': 8, 'max': 14},
          ],
          'affixRules': {
            'prefixMin': 0,
            'prefixMax': 0,
            'suffixMin': 0,
            'suffixMax': 0,
            'allowedTags': ['poison'],
          },
        },
      ],
    }),
    _file('assets/data/quality_config.json', {
      'schemaVersion': 1,
      'qualities': [
        {
          'id': 'normal',
          'name': '普通',
          'affixMin': 0,
          'affixMax': 0,
          'statMultiplier': 1.0,
          'specialEffectChance': 0.0,
        },
        {
          'id': 'rare',
          'name': '稀有',
          'affixMin': 0,
          'affixMax': 0,
          'statMultiplier': 1.18,
          'specialEffectChance': 0.02,
        },
      ],
    }),
    _file('assets/data/affixes.json', {
      'schemaVersion': 1,
      'affixes': <Object?>[],
    }),
  ]);
}

Map<String, Object?> _monster(
  String id,
  String name,
  num hp,
  num attack,
  num armor,
  int experience,
  int gold,
  Map<String, int> materials,
) {
  return {
    'id': id,
    'name': name,
    'level': 1,
    'tags': ['test'],
    'baseStats': {'hp': hp, 'attack': attack, 'armor': armor},
    'rewards': {
      'experience': experience,
      'gold': gold,
      'materials': materials,
    },
    'dropPoolId': 'drop_equipment',
  };
}

Map<String, Object?> _stage(
  String id,
  String name,
  String monsterId,
  int requiredLevel, {
  bool isBoss = false,
}) {
  return {
    'stageId': id,
    'stageName': name,
    'monsterIds': [monsterId],
    'requiredLevel': requiredLevel,
    'isBossStage': isBoss,
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
