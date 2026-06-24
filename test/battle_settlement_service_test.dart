import 'package:abyss_relic/models/battle_state.dart';
import 'package:abyss_relic/models/battle_settlement_report.dart';
import 'package:abyss_relic/models/data_file_meta.dart';
import 'package:abyss_relic/models/loaded_data_file.dart';
import 'package:abyss_relic/models/monster_config.dart';
import 'package:abyss_relic/models/monster_runtime.dart';
import 'package:abyss_relic/models/save_data.dart';
import 'package:abyss_relic/models/stat_block.dart';
import 'package:abyss_relic/systems/battle/battle_settlement_service.dart';
import 'package:abyss_relic/systems/config/data_loader.dart';
import 'package:abyss_relic/systems/config/game_database.dart';
import 'package:abyss_relic/systems/config/game_database_service.dart';
import 'package:abyss_relic/systems/monsters/monster_service.dart';
import 'package:abyss_relic/systems/stats/stat_aggregation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('victory settlement grants experience', () {
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 24));

    final report = _service().settle(
      battle: _battle(result: BattleResult.victory),
      monster: _monster(experience: 12),
      saveData: save,
      database: _database(includeDrop: false),
      seed: 1,
    );

    expect(report.accepted, isTrue);
    expect(report.gainedExperience, 12);
    expect(report.saveData.playerProgress.experience, 12);
    expect(report.saveData.playerProgress.level, 1);
  });

  test('non-victory battle does not settle rewards', () {
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 24));

    final report = _service().settle(
      battle: _battle(result: BattleResult.running),
      monster: _monster(experience: 12, gold: 3),
      saveData: save,
      database: _database(includeDrop: false),
      seed: 1,
    );

    expect(report.accepted, isFalse);
    expect(report.reason, BattleSettlementReason.notVictory);
    expect(report.saveData, save);
    expect(report.saveData.playerProgress.experience, 0);
    expect(report.saveData.inventory.materials, isEmpty);
  });

  test('defeat battle does not grant rewards or equipment drops', () {
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 24));

    final report = _service().settle(
      battle: _battle(result: BattleResult.defeat),
      monster: _monster(experience: 12, gold: 3, dropPoolId: 'drop_equipment'),
      saveData: save,
      database: _database(includeDrop: true),
      seed: 3,
    );

    expect(report.accepted, isFalse);
    expect(report.reason, BattleSettlementReason.notVictory);
    expect(report.saveData, save);
    expect(report.generatedEquipment, isEmpty);
    expect(report.rejectedEquipment, isEmpty);
    expect(report.saveData.playerProgress.experience, 0);
    expect(report.saveData.inventory.materials, isEmpty);
  });

  test('gold and monster material rewards are stored as materials', () {
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 24));

    final report = _service().settle(
      battle: _battle(result: BattleResult.victory),
      monster: _monster(
        gold: 7,
        materials: const {'bone_shard': 2},
      ),
      saveData: save,
      database: _database(includeDrop: false),
      seed: 1,
    );

    expect(report.gainedGold, 7);
    expect(report.gainedMaterials.map((material) => material.materialId), [
      'gold',
      'bone_shard',
    ]);
    expect(_materialQuantity(report.saveData, 'gold'), 7);
    expect(_materialQuantity(report.saveData, 'bone_shard'), 2);
  });

  test('drop pool equipment enters full equipment instances', () {
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 24));

    final report = _service().settle(
      battle: _battle(result: BattleResult.victory),
      monster: _monster(dropPoolId: 'drop_equipment'),
      saveData: save,
      database: _database(includeDrop: true),
      seed: 3,
    );

    expect(report.accepted, isTrue);
    expect(report.generatedEquipment, hasLength(1));
    final equipment = report.generatedEquipment.single;
    expect(
        report.saveData.inventory.equipmentInstanceIds, [equipment.instanceId]);
    expect(
      report.saveData.inventory.equipmentInstances[equipment.instanceId],
      equipment,
    );
    expect(equipment.templateId, 'rusted_blade');
  });

  test('full equipment bag rejects drops without orphan instances', () {
    final existingSave =
        SaveData.newGame(now: DateTime.utc(2026, 6, 24)).copyWith(
      inventory: const InventorySave(
        equipmentInstanceIds: ['existing'],
        equipmentCapacity: 1,
      ),
    );

    final report = _service().settle(
      battle: _battle(result: BattleResult.victory),
      monster: _monster(dropPoolId: 'drop_equipment'),
      saveData: existingSave,
      database: _database(includeDrop: true),
      seed: 3,
    );

    expect(report.generatedEquipment, isEmpty);
    expect(report.rejectedEquipment, hasLength(1));
    expect(report.saveData.inventory.equipmentInstanceIds, ['existing']);
    expect(report.saveData.inventory.equipmentInstances, isEmpty);
  });

  test('experience settlement can level up through LevelService', () {
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 24));

    final report = _service().settle(
      battle: _battle(result: BattleResult.victory),
      monster: _monster(experience: 100),
      saveData: save,
      database: _database(includeDrop: false),
      seed: 1,
    );

    expect(report.leveledUp, isTrue);
    expect(report.newLevel, 2);
    expect(report.saveData.playerProgress.level, 2);
    expect(report.saveData.playerProgress.experience, 100);
  });

  test('seed skeleton_grunt can settle experience, gold, and equipment drop',
      () async {
    final loadResult = await const GameDatabaseService(
      dataLoader: DataLoader(),
    ).loadDataDirectory();
    final monster =
        MonsterService(loadResult.database).requireMonster('skeleton_grunt');
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 24));

    final report = [
      for (var seed = 1; seed <= 200; seed += 1)
        _service().settle(
          battle: _battle(result: BattleResult.victory),
          monster: monster,
          saveData: save,
          database: loadResult.database,
          seed: seed,
        ),
    ].firstWhere((report) => report.generatedEquipment.isNotEmpty);

    expect(report.accepted, isTrue);
    expect(report.gainedExperience, monster.rewards.experience);
    expect(
        report.saveData.playerProgress.experience, monster.rewards.experience);
    expect(_materialQuantity(report.saveData, 'gold'), monster.rewards.gold);
    expect(report.generatedEquipment.single.templateId, isNotEmpty);
    expect(report.saveData.inventory.equipmentInstances,
        contains(report.generatedEquipment.single.instanceId));
  });
}

BattleSettlementService _service() => const BattleSettlementService();

BattleState _battle({required BattleResult result}) {
  return BattleState(
    battleId: 'battle_test',
    characterClassId: 'exile',
    characterStats: const StatAggregationService().compute(
      base: const StatBlock(hp: 100, attack: 20, armor: 5),
    ),
    skillRuntimes: const [],
    skillConfigs: const {},
    monster: const MonsterRuntime(
      monsterId: 'skeleton_grunt',
      level: 1,
      maxHp: 85,
      currentHp: 0,
      attack: 10,
      armor: 4,
      tags: ['undead'],
    ),
    elapsedSeconds: 5,
    logs: const [],
    result: result,
  );
}

MonsterConfig _monster({
  int experience = 0,
  int gold = 0,
  Map<String, int> materials = const {},
  String dropPoolId = 'drop_empty',
}) {
  return MonsterConfig(
    id: 'skeleton_grunt',
    name: 'Skeleton Grunt',
    level: 1,
    tags: const ['undead'],
    baseStats: const StatBlock(hp: 85, attack: 10, armor: 4),
    rewards: MonsterRewards(
      experience: experience,
      gold: gold,
      materials: materials,
    ),
    dropPoolId: dropPoolId,
  );
}

int _materialQuantity(SaveData save, String materialId) {
  return save.inventory.materials
      .firstWhere((material) => material.materialId == materialId)
      .quantity;
}

GameDatabase _database({required bool includeDrop}) {
  return GameDatabase.fromFiles([
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
        if (includeDrop)
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
        {
          'id': 'drop_empty',
          'name': 'Empty Drop',
          'entries': <Object?>[],
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
