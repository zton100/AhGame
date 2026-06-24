import 'package:abyss_relic/core/save/player_save_provider.dart';
import 'package:abyss_relic/core/theme/app_theme.dart';
import 'package:abyss_relic/features/battle/battle_page.dart';
import 'package:abyss_relic/models/data_file_meta.dart';
import 'package:abyss_relic/models/loaded_data_file.dart';
import 'package:abyss_relic/models/save_data.dart';
import 'package:abyss_relic/systems/config/game_database.dart';
import 'package:abyss_relic/systems/config/game_database_load_result.dart';
import 'package:abyss_relic/systems/config/game_database_service.dart';
import 'package:abyss_relic/systems/save/in_memory_save_store.dart';
import 'package:abyss_relic/systems/save/save_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BattlePage displays for a new save', (tester) async {
    final saveService = SaveService(store: InMemorySaveStore());

    await tester.pumpWidget(_app(saveService: saveService));
    await tester.pumpAndSettle();

    expect(find.text('Battle'), findsOneWidget);
    expect(find.text('Start Battle'), findsOneWidget);
    expect(find.text('Run 1 Battle'), findsOneWidget);
    expect(find.text('Run 10 Battles'), findsOneWidget);
    expect(find.text('not_started'), findsOneWidget);
    expect(find.text('Chapter 1'), findsOneWidget);
    expect(find.text('1-1 Grave Road'), findsOneWidget);
  });

  testWidgets('starting battle creates battle state on the page',
      (tester) async {
    final saveService = SaveService(store: InMemorySaveStore());

    await tester.pumpWidget(_app(saveService: saveService));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Battle'));
    await tester.pumpAndSettle();

    expect(find.text('Skeleton Grunt'), findsOneWidget);
    expect(find.text('running'), findsOneWidget);
    expect(find.text('85 / 85'), findsOneWidget);
    expect(find.text('Player HP'), findsOneWidget);
    expect(find.text('100 / 100'), findsOneWidget);
  });

  testWidgets('ticking battle damages the monster', (tester) async {
    final saveService = SaveService(store: InMemorySaveStore());

    await tester.pumpWidget(_app(saveService: saveService));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Battle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tick 1s'));
    await tester.pumpAndSettle();

    expect(find.text('85 / 85'), findsNothing);
    expect(find.textContaining('toxic_slash cast.'), findsOneWidget);
  });

  testWidgets('victory settlement saves experience and dropped equipment',
      (tester) async {
    final saveService = SaveService(store: InMemorySaveStore());

    await tester.pumpWidget(_app(saveService: saveService));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Battle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Auto Finish'));
    await tester.pumpAndSettle();

    expect(find.text('victory'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Settlement'), 200);
    expect(find.text('Settlement'), findsOneWidget);
    expect(find.text('Dropped equipment'), findsOneWidget);

    final save = await saveService.loadOrCreate();
    expect(save.playerProgress.experience, 12);
    expect(save.playerProgress.currentStageId, '1-2');
    expect(save.playerProgress.highestClearedStageId, '1-1');
    expect(save.inventory.equipmentInstanceIds, hasLength(1));
    final instanceId = save.inventory.equipmentInstanceIds.single;
    expect(save.inventory.equipmentInstances[instanceId]?.templateId,
        'rusted_blade');
  });

  testWidgets('repeated settlement does not grant rewards twice',
      (tester) async {
    final saveService = SaveService(store: InMemorySaveStore());

    await tester.pumpWidget(_app(saveService: saveService));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Battle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Auto Finish'));
    await tester.pumpAndSettle();

    final firstSave = await saveService.loadOrCreate();
    await tester.tap(find.text('Auto Finish'), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settle Victory'), warnIfMissed: false);
    await tester.pumpAndSettle();

    final secondSave = await saveService.loadOrCreate();
    expect(secondSave.playerProgress.experience,
        firstSave.playerProgress.experience);
    expect(secondSave.playerProgress.currentStageId,
        firstSave.playerProgress.currentStageId);
    expect(secondSave.inventory.equipmentInstanceIds,
        firstSave.inventory.equipmentInstanceIds);
  });

  testWidgets('BattlePage displays accumulated auto battle rewards',
      (tester) async {
    final saveService = SaveService(store: InMemorySaveStore());

    await tester.pumpWidget(_app(saveService: saveService));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Run 10 Battles'));
    await tester.pumpAndSettle();

    expect(find.text('Completed Battles'), findsOneWidget);
    expect(find.text('Total EXP'), findsOneWidget);
    expect(find.text('21'), findsOneWidget);
    expect(find.text('chapterComplete'), findsOneWidget);

    final save = await saveService.loadOrCreate();
    expect(save.playerProgress.experience, 21);
    expect(save.inventory.equipmentInstanceIds, hasLength(2));
  });

  testWidgets('BattlePage displays farming fallback status', (tester) async {
    final saveService = SaveService(store: InMemorySaveStore());
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 24)).copyWith(
      playerProgress: SaveData.newGame().playerProgress.copyWith(
            currentStageId: '1-2',
            highestClearedStageId: '1-1',
          ),
    );
    await saveService.save(save);

    await tester.pumpWidget(
      _app(
        saveService: saveService,
        database: _database(secondStageRequiredLevel: 99),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Run 1 Battle'));
    await tester.pumpAndSettle();

    expect(find.text('Progression Stage'), findsOneWidget);
    expect(find.text('Farming Stage'), findsOneWidget);
    expect(find.text('Farming Because Level Too Low'), findsOneWidget);
    expect(find.text('true'), findsOneWidget);
    expect(
      find.text(
        'Current stage level is too high. Auto battle is farming the highest cleared stage you can enter.',
      ),
      findsOneWidget,
    );

    final updatedSave = await saveService.loadOrCreate();
    expect(updatedSave.playerProgress.currentStageId, '1-2');
    expect(updatedSave.playerProgress.experience, 12);
  });

  testWidgets('BattlePage displays defeat state and player HP', (tester) async {
    final saveService = SaveService(store: InMemorySaveStore());

    await tester.pumpWidget(
      _app(
        saveService: saveService,
        database: _database(
          classHp: 10,
          classAttack: 1,
          monsterHp: 500,
          monsterAttack: 999,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Battle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Auto Finish'));
    await tester.pumpAndSettle();

    expect(find.text('Player HP'), findsOneWidget);
    expect(find.text('defeat'), findsOneWidget);
    expect(
      find.text(
        'Battle failed. Enhance gear, adjust equipment, or repeat cleared stages to grow stronger.',
      ),
      findsOneWidget,
    );

    final save = await saveService.loadOrCreate();
    expect(save.playerProgress.experience, 0);
    expect(save.playerProgress.currentStageId, '1-1');
  });

  testWidgets('BattlePage displays auto battle failure stop reason',
      (tester) async {
    final saveService = SaveService(store: InMemorySaveStore());

    await tester.pumpWidget(
      _app(
        saveService: saveService,
        database: _database(
          classHp: 10,
          classAttack: 1,
          monsterHp: 500,
          monsterAttack: 999,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Run 1 Battle'));
    await tester.pumpAndSettle();

    expect(find.text('Stop Reason'), findsOneWidget);
    expect(find.text('battleFailed'), findsOneWidget);
    expect(find.textContaining('Battle lost.'), findsOneWidget);
  });

  testWidgets('BattlePage displays unsafe farming fallback', (tester) async {
    final saveService = SaveService(store: InMemorySaveStore());
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 24)).copyWith(
      playerProgress: SaveData.newGame().playerProgress.copyWith(
            currentStageId: '1-2',
            highestClearedStageId: '1-1',
          ),
    );
    await saveService.save(save);

    await tester.pumpWidget(
      _app(
        saveService: saveService,
        database: _database(
          monsterHp: 20,
          monsterAttack: 0,
          secondMonsterHp: 500,
          secondMonsterAttack: 999,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Run 1 Battle'));
    await tester.pumpAndSettle();

    expect(find.text('Progress Mode'), findsOneWidget);
    expect(find.text('farming_unsafe'), findsOneWidget);
    expect(find.text('Farming Because Unsafe'), findsOneWidget);
    expect(find.text('true'), findsOneWidget);
    expect(
      find.text(
        'Current progression stage looks unsafe. Auto battle is farming the highest cleared stage first.',
      ),
      findsOneWidget,
    );
  });
}

Widget _app({
  required SaveService saveService,
  GameDatabase? database,
}) {
  return ProviderScope(
    overrides: [
      saveServiceProvider.overrideWithValue(saveService),
      gameDatabaseLoadProvider.overrideWith((ref) async {
        return GameDatabaseLoadResult(
          database: database ?? _database(),
          errors: const [],
        );
      }),
    ],
    child: MaterialApp(
      theme: AppTheme.dark(),
      home: const Scaffold(body: BattlePage()),
    ),
  );
}

GameDatabase _database({
  int secondStageRequiredLevel = 1,
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
        {
          'id': 'skeleton_grunt',
          'name': 'Skeleton Grunt',
          'level': 1,
          'tags': ['undead'],
          'baseStats': {
            'hp': monsterHp,
            'attack': monsterAttack,
            'armor': 4,
          },
          'rewards': {
            'experience': 12,
            'gold': 3,
            'materials': {'bone_shard': 1},
          },
          'dropPoolId': 'drop_equipment',
        },
        {
          'id': 'plague_rat',
          'name': 'Plague Rat',
          'level': 1,
          'tags': ['beast', 'poison'],
          'baseStats': {
            'hp': secondMonsterHp,
            'attack': secondMonsterAttack,
            'armor': 1,
          },
          'rewards': {
            'experience': 9,
            'gold': 2,
            'materials': <String, Object?>{},
          },
          'dropPoolId': 'drop_equipment',
        },
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
            {
              'stageId': '1-1',
              'stageName': 'Grave Road',
              'monsterIds': ['skeleton_grunt'],
              'requiredLevel': 1,
              'isBossStage': false,
            },
            {
              'stageId': '1-2',
              'stageName': 'Rat Cellar',
              'monsterIds': ['plague_rat'],
              'requiredLevel': secondStageRequiredLevel,
              'isBossStage': false,
            },
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
