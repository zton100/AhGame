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

    expect(find.text('战斗'), findsOneWidget);
    expect(find.text('开始战斗'), findsOneWidget);
    expect(find.text('运行 1 场'), findsOneWidget);
    expect(find.text('运行 10 场'), findsOneWidget);
    expect(find.text('未开始'), findsOneWidget);
    expect(find.text('第一章：墓园边境'), findsOneWidget);
    expect(find.text('1-1 墓园小路'), findsOneWidget);
  });

  testWidgets('starting battle creates battle state on the page',
      (tester) async {
    final saveService = SaveService(store: InMemorySaveStore());

    await tester.pumpWidget(_app(saveService: saveService));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始战斗'));
    await tester.pumpAndSettle();

    expect(find.text('亡骨杂兵'), findsOneWidget);
    expect(find.text('进行中'), findsOneWidget);
    expect(find.text('85 / 85'), findsOneWidget);
    expect(find.text('玩家生命'), findsOneWidget);
    expect(find.text('100 / 100'), findsOneWidget);
  });

  testWidgets('ticking battle damages the monster', (tester) async {
    final saveService = SaveService(store: InMemorySaveStore());

    await tester.pumpWidget(_app(saveService: saveService));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始战斗'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('推进 1 秒'));
    await tester.pumpAndSettle();

    expect(find.text('85 / 85'), findsNothing);
    expect(find.textContaining('释放技能：毒刃。'), findsOneWidget);
  });

  testWidgets('victory settlement saves experience and dropped equipment',
      (tester) async {
    final saveService = SaveService(store: InMemorySaveStore());

    await tester.pumpWidget(_app(saveService: saveService));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始战斗'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('自动打完'));
    await tester.pumpAndSettle();

    expect(find.text('胜利'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('结算报告'), 200);
    expect(find.text('结算报告'), findsOneWidget);
    expect(find.text('掉落装备'), findsOneWidget);

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
    await tester.tap(find.text('开始战斗'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('自动打完'));
    await tester.pumpAndSettle();

    final firstSave = await saveService.loadOrCreate();
    await tester.tap(find.text('自动打完'), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('结算胜利'), warnIfMissed: false);
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
    await tester.tap(find.text('运行 10 场'));
    await tester.pumpAndSettle();

    expect(find.text('完成场次'), findsOneWidget);
    expect(find.text('总经验'), findsOneWidget);
    expect(find.text('自动战斗说明'), findsOneWidget);
    expect(find.text('下一步建议'), findsOneWidget);
    expect(find.text('继续推进'), findsOneWidget);
    expect(find.text('当前战斗预估安全，可以继续推进。'), findsOneWidget);
    expect(find.text('21'), findsOneWidget);
    expect(find.text('章节完成'), findsOneWidget);

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
    await tester.tap(find.text('运行 1 场'));
    await tester.pumpAndSettle();

    expect(find.text('推进关卡'), findsWidgets);
    expect(find.text('刷取关卡'), findsOneWidget);
    expect(find.text('实际关卡'), findsOneWidget);
    expect(find.text('因等级不足回刷'), findsWidgets);
    expect(find.text('刷旧关积累材料'), findsOneWidget);
    expect(find.text('是'), findsWidgets);
    expect(
      find.text(
        '当前关卡等级要求过高，正在自动刷最高可进入的已通关关卡。',
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
    await tester.tap(find.text('开始战斗'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('自动打完'));
    await tester.pumpAndSettle();

    expect(find.text('玩家生命'), findsOneWidget);
    expect(find.text('失败'), findsOneWidget);
    expect(
      find.text(
        '战斗失败。请强化装备、调整装备，或重复刷已通关关卡提升实力。',
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
    await tester.tap(find.text('运行 1 场'));
    await tester.pumpAndSettle();

    expect(find.text('停止原因'), findsOneWidget);
    expect(find.text('战斗失败'), findsOneWidget);
    expect(find.textContaining('战斗失败。'), findsWidgets);
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
    await tester.tap(find.text('运行 1 场'));
    await tester.pumpAndSettle();

    expect(find.text('推进模式'), findsWidgets);
    expect(find.text('危险评估回刷'), findsOneWidget);
    expect(find.text('因危险评估回刷'), findsOneWidget);
    expect(find.text('自动战斗说明'), findsOneWidget);
    expect(find.text('生存不足'), findsOneWidget);
    expect(find.text('强化护甲或生命装备'), findsOneWidget);
    expect(
      find.text('生存不足，建议强化护甲/生命装备，或更换更高生存属性装备。'),
      findsOneWidget,
    );
    expect(find.text('是'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('当前推进关卡风险较高，正在优先刷最高已通关关卡。'),
      200,
    );
    expect(
      find.text(
        '当前推进关卡风险较高，正在优先刷最高已通关关卡。',
      ),
      findsOneWidget,
    );
  });

  testWidgets('BattlePage explains low damage fallback', (tester) async {
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
          secondMonsterHp: 10000,
          secondMonsterAttack: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('运行 1 场'));
    await tester.pumpAndSettle();

    expect(find.text('自动战斗说明'), findsOneWidget);
    expect(find.text('因伤害不足回刷'), findsOneWidget);
    expect(find.text('伤害不足'), findsOneWidget);
    expect(find.text('强化武器'), findsOneWidget);
    expect(
      find.text('伤害不足，建议优先强化主武器或更换高攻击装备。'),
      findsOneWidget,
    );
    expect(find.text('推进关卡'), findsWidgets);
    expect(find.text('实际关卡'), findsOneWidget);
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
          'name': '流放者',
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
          'name': '毒刃',
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
          'name': '亡骨杂兵',
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
          'name': '瘟疫鼠',
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
          'name': '第一章：墓园边境',
          'stages': [
            {
              'stageId': '1-1',
              'stageName': '墓园小路',
              'monsterIds': ['skeleton_grunt'],
              'requiredLevel': 1,
              'isBossStage': false,
            },
            {
              'stageId': '1-2',
              'stageName': '鼠群地窖',
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
