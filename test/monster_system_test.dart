import 'package:abyss_relic/models/data_file_meta.dart';
import 'package:abyss_relic/models/loaded_data_file.dart';
import 'package:abyss_relic/models/monster_config.dart';
import 'package:abyss_relic/models/monster_runtime.dart';
import 'package:abyss_relic/systems/config/data_loader.dart';
import 'package:abyss_relic/systems/config/game_database.dart';
import 'package:abyss_relic/systems/config/game_database_service.dart';
import 'package:abyss_relic/systems/monsters/monster_factory.dart';
import 'package:abyss_relic/systems/monsters/monster_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('monsters.json loads into GameDatabase', () async {
    final result = await const GameDatabaseService(
      dataLoader: DataLoader(),
    ).loadDataDirectory();

    expect(result.issues, isEmpty);
    expect(result.database.findRecord('monsters', 'skeleton_grunt'), isNotNull);
    expect(result.database.findRecord('monsters', 'plague_rat'), isNotNull);
    expect(result.database.findRecord('monsters', 'blood_cultist'), isNotNull);
    expect(result.database.findRecord('monsters', 'abyss_imp'), isNotNull);
    expect(result.database.findRecord('monsters', 'training_dummy'), isNotNull);
  });

  test('MonsterConfig parses monster records', () {
    final monster = MonsterConfig.fromJson(_monsterRecord());

    expect(monster.id, 'skeleton_grunt');
    expect(monster.name, 'Skeleton Grunt');
    expect(monster.level, 1);
    expect(monster.tags, containsAll(['undead', 'melee']));
    expect(monster.baseStats.hp, 85);
    expect(monster.baseStats.attack, 10);
    expect(monster.rewards.experience, 12);
    expect(monster.dropPoolId, 'drop_chapter_1');
    expect(monster.resistances['shadow'], 0.15);
  });

  test('MonsterService can query monsters by tag and level range', () {
    final service = MonsterService(_database());

    expect(service.requireMonster('plague_rat').tags, contains('poison'));
    expect(service.monstersByTag('poison').map((monster) => monster.id), [
      'plague_rat',
    ]);
    expect(
      service
          .monstersForLevelRange(minLevel: 1, maxLevel: 2)
          .map((monster) => monster.id),
      ['plague_rat', 'skeleton_grunt'],
    );
  });

  test('MonsterRuntime damage lowers hp without going below zero', () {
    const monster = MonsterRuntime(
      monsterId: 'training_dummy',
      level: 1,
      maxHp: 200,
      currentHp: 200,
      attack: 0,
      armor: 0,
      tags: ['training'],
    );

    final damaged = monster.takeDamage(45);
    final killed = damaged.takeDamage(999);

    expect(damaged.currentHp, 155);
    expect(damaged.isAlive, isTrue);
    expect(killed.currentHp, 0);
    expect(killed.isAlive, isFalse);
  });

  test('MonsterRuntime supports JSON round trip and optional healing', () {
    const monster = MonsterRuntime(
      monsterId: 'training_dummy',
      level: 1,
      maxHp: 200,
      currentHp: 80,
      attack: 0,
      armor: 0,
      tags: ['training'],
    );

    final healed = monster.heal(50);
    final restored = MonsterRuntime.fromJson(healed.toJson());

    expect(healed.currentHp, 130);
    expect(healed.heal(999).currentHp, 200);
    expect(restored.monsterId, 'training_dummy');
    expect(restored.currentHp, 130);
    expect(restored.tags, ['training']);
  });

  test('MonsterFactory creates runtime monsters with level scaling', () {
    final config = MonsterConfig.fromJson(_monsterRecord());

    final runtime = const MonsterFactory().create(
      config: config,
      level: 3,
    );

    expect(runtime.monsterId, 'skeleton_grunt');
    expect(runtime.level, 3);
    expect(runtime.maxHp, closeTo(85 * 1.24, 0.0001));
    expect(runtime.currentHp, runtime.maxHp);
    expect(runtime.attack, closeTo(10 * 1.20, 0.0001));
    expect(runtime.armor, closeTo(4 * 1.16, 0.0001));
    expect(runtime.tags, contains('undead'));
  });

  test('MonsterService validates dropPoolId references', () {
    final validErrors =
        MonsterService(_database()).validateDropPoolReferences();
    final invalidErrors = MonsterService(_database(includeDropPool: false))
        .validateDropPoolReferences();

    expect(validErrors, isEmpty);
    expect(invalidErrors.map((error) => error.recordId), [
      'skeleton_grunt',
      'plague_rat',
    ]);
    expect(invalidErrors.every((error) => error.field == 'dropPoolId'), isTrue);
  });
}

GameDatabase _database({bool includeDropPool = true}) {
  return GameDatabase.fromFiles([
    _file('assets/data/monsters.json', {
      'schemaVersion': 1,
      'monsters': [
        _monsterRecord(),
        {
          'id': 'plague_rat',
          'name': 'Plague Rat',
          'level': 1,
          'tags': ['beast', 'poison'],
          'baseStats': {'hp': 55, 'attack': 8, 'armor': 1},
          'rewards': {'experience': 9, 'gold': 2},
          'dropPoolId': 'drop_chapter_1',
        },
      ],
    }),
    if (includeDropPool)
      _file('assets/data/drop_pools.json', {
        'schemaVersion': 1,
        'drop_pools': [
          {'id': 'drop_chapter_1', 'name': 'Chapter 1', 'entries': []},
        ],
      }),
  ]);
}

Map<String, Object?> _monsterRecord() {
  return {
    'id': 'skeleton_grunt',
    'name': 'Skeleton Grunt',
    'level': 1,
    'tags': ['undead', 'melee', 'physical'],
    'baseStats': {'hp': 85, 'attack': 10, 'armor': 4},
    'rewards': {'experience': 12, 'gold': 3},
    'dropPoolId': 'drop_chapter_1',
    'skills': <String>[],
    'resistances': {'shadow': 0.15, 'holy': -0.1},
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
