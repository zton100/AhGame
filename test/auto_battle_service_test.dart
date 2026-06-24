import 'package:abyss_relic/models/auto_battle_run_state.dart';
import 'package:abyss_relic/models/data_file_meta.dart';
import 'package:abyss_relic/models/loaded_data_file.dart';
import 'package:abyss_relic/models/save_data.dart';
import 'package:abyss_relic/systems/auto_battle/auto_battle_service.dart';
import 'package:abyss_relic/systems/config/game_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('runOneBattle grants experience', () async {
    SaveData? saved;

    final result = await _service().runOneBattle(
      saveData: SaveData.newGame(now: DateTime.utc(2026, 6, 24)),
      database: _database(),
      save: (saveData) async => saved = saveData,
    );

    expect(result.battlesCompleted, 1);
    expect(result.totalExperience, 12);
    expect(result.saveData.playerProgress.experience, 12);
    expect(saved?.playerProgress.experience, 12);
  });

  test('runOneBattle stores generated equipment in the save', () async {
    final result = await _service().runOneBattle(
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

    final result = await _service().runManyBattles(
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
    final result = await _service().runManyBattles(
      saveData: SaveData.newGame(now: DateTime.utc(2026, 6, 24)),
      database: _database(stageCount: 3),
      maxBattles: 2,
      save: (_) async {},
    );

    expect(result.battlesCompleted, 2);
    expect(result.stopReason, AutoBattleStopReason.maxBattlesReached);
    expect(result.saveData.playerProgress.currentStageId, '1-3');
  });

  test('level too low stops without crashing', () async {
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 24)).copyWith(
      playerProgress: SaveData.newGame().playerProgress.copyWith(
            currentStageId: '1-2',
          ),
    );

    final result = await _service().runOneBattle(
      saveData: save,
      database: _database(secondStageRequiredLevel: 99),
      save: (_) async => fail('level too low should not save'),
    );

    expect(result.battlesCompleted, 0);
    expect(result.stopReason, AutoBattleStopReason.levelTooLow);
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
}

AutoBattleService _service() => const AutoBattleService();

GameDatabase _database({
  int stageCount = 2,
  int secondStageRequiredLevel = 1,
}) {
  return GameDatabase.fromFiles([
    _file('assets/data/classes.json', {
      'schemaVersion': 1,
      'classes': [
        {
          'id': 'exile',
          'name': 'Exile',
          'tags': ['poison'],
          'baseStats': {'hp': 100, 'attack': 18, 'armor': 6},
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
        _monster('skeleton_grunt', 'Skeleton Grunt', 85, 10, 4, 12, 3,
            {'bone_shard': 1}),
        _monster('plague_rat', 'Plague Rat', 55, 8, 1, 9, 2, {}),
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
          'qualityPool': ['rare'],
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
          'id': 'rare',
          'name': 'Rare',
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
