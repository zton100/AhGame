import 'package:abyss_relic/core/save/player_save_provider.dart';
import 'package:abyss_relic/core/theme/app_theme.dart';
import 'package:abyss_relic/features/equipment/equipment_page.dart';
import 'package:abyss_relic/models/affix_config.dart';
import 'package:abyss_relic/models/data_file_meta.dart';
import 'package:abyss_relic/models/equipment_instance.dart';
import 'package:abyss_relic/models/inventory_state.dart';
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
  testWidgets('EquipmentPage shows empty inventory from an empty save',
      (tester) async {
    final saveService = SaveService(store: InMemorySaveStore());

    await tester.pumpWidget(_app(saveService: saveService));
    await tester.pumpAndSettle();

    expect(find.text('背包暂无装备'), findsOneWidget);
    expect(find.text('击败敌人后获得的装备会出现在这里。'), findsOneWidget);
  });

  testWidgets('EquipmentPage generates test equipment through SaveData',
      (tester) async {
    final saveService = SaveService(store: InMemorySaveStore());

    await tester.pumpWidget(_app(saveService: saveService));
    await tester.pumpAndSettle();

    await tester.tap(find.text('生成测试装备到背包'));
    await tester.pumpAndSettle();

    expect(find.text('Rusted Blade'), findsOneWidget);
    expect(find.textContaining('Rare'), findsOneWidget);
    expect(find.textContaining('BD'), findsWidgets);
    expect(find.textContaining('推荐 poison'), findsOneWidget);
  });

  testWidgets('EquipmentPage reloads saved equipment after SaveService reload',
      (tester) async {
    final store = InMemorySaveStore();
    final firstService = SaveService(store: store);

    await tester.pumpWidget(_app(saveService: firstService));
    await tester.pumpAndSettle();
    await tester.tap(find.text('生成测试装备到背包'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());

    final secondService = SaveService(store: store);
    await tester.pumpWidget(_app(saveService: secondService));
    await tester.pumpAndSettle();

    expect(find.text('Rusted Blade'), findsOneWidget);
  });

  testWidgets('EquipmentPage shows equipment card and detail dialog',
      (tester) async {
    final saveService = SaveService(store: InMemorySaveStore());
    await saveService.save(SaveData.newGame().copyWith(
      inventory: inventorySaveFromState(InventoryState(
        equipmentInstanceIds: const ['eq_poison_blade'],
        equipmentInstances: {'eq_poison_blade': _equipment()},
      )),
    ));

    await tester.pumpWidget(_app(saveService: saveService));
    await tester.pumpAndSettle();

    expect(find.text('Poison Blade'), findsOneWidget);
    expect(find.textContaining('Rare'), findsOneWidget);
    expect(find.textContaining('BD'), findsWidgets);
    expect(find.textContaining('推荐 poison'), findsOneWidget);

    await tester.tap(find.text('Poison Blade'));
    await tester.pumpAndSettle();

    expect(find.text('基础属性'), findsOneWidget);
    expect(find.text('词缀'), findsOneWidget);
    expect(find.text('BD 匹配'), findsOneWidget);
    expect(find.textContaining('Poison Damage'), findsWidgets);
    expect(find.textContaining('matchedTags'), findsOneWidget);
  });
}

Widget _app({required SaveService saveService}) {
  return ProviderScope(
    overrides: [
      saveServiceProvider.overrideWithValue(saveService),
      gameDatabaseLoadProvider.overrideWith((ref) async {
        return GameDatabaseLoadResult(
          database: _database(),
          errors: const [],
        );
      }),
    ],
    child: MaterialApp(
      theme: AppTheme.dark(),
      home: const Scaffold(body: EquipmentPage()),
    ),
  );
}

EquipmentInstance _equipment() {
  return EquipmentInstance(
    instanceId: 'eq_poison_blade',
    templateId: 'poison_blade',
    qualityId: 'rare',
    level: 5,
    createdAt: DateTime.utc(2026, 6, 24),
    rolledBaseStats: const [
      RolledBaseStat(stat: 'attack', value: 18),
    ],
    rolledAffixes: const [
      RolledAffix(
        affixId: 'aff_poison_damage',
        rollValue: 0.12,
        exclusiveGroup: 'element_damage',
      ),
    ],
  );
}

GameDatabase _database() {
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
    _file('assets/data/equipment_templates.json', {
      'schemaVersion': 1,
      'equipment_templates': [
        {
          'id': 'rusted_blade',
          'name': 'Rusted Blade',
          'slot': 'main_weapon',
          'allowedClasses': ['exile'],
          'minLevel': 1,
          'qualityPool': ['normal', 'magic', 'rare'],
          'baseStats': [
            {'stat': 'attack', 'min': 8, 'max': 14},
          ],
          'affixRules': {
            'prefixMin': 0,
            'prefixMax': 1,
            'suffixMin': 0,
            'suffixMax': 1,
            'allowedTags': ['poison', 'shadow'],
          },
        },
        {
          'id': 'poison_blade',
          'name': 'Poison Blade',
          'slot': 'main_weapon',
          'allowedClasses': ['exile'],
          'minLevel': 1,
          'qualityPool': ['rare'],
          'baseStats': [
            {'stat': 'attack', 'min': 8, 'max': 14},
          ],
          'affixRules': {
            'prefixMin': 0,
            'prefixMax': 1,
            'suffixMin': 0,
            'suffixMax': 1,
            'allowedTags': ['poison', 'shadow'],
          },
        },
      ],
    }),
    _file('assets/data/affixes.json', {
      'schemaVersion': 1,
      'affixes': [
        {
          'id': 'aff_poison_damage',
          'name': 'Poison Damage',
          'type': 'element',
          'tags': ['poison'],
          'minLevel': 1,
          'weight': 100,
          'exclusiveGroup': 'element_damage',
          'rollRange': {'min': 0.06, 'max': 0.18, 'step': 0.01},
          'statModifiers': [
            {'stat': 'poison_damage', 'mode': 'percent', 'valueFromRoll': true},
          ],
        },
      ],
    }),
    _file('assets/data/quality_config.json', {
      'schemaVersion': 1,
      'qualities': [
        {
          'id': 'normal',
          'name': 'Normal',
          'affixMin': 0,
          'affixMax': 0,
          'statMultiplier': 1,
          'specialEffectChance': 0,
        },
        {
          'id': 'magic',
          'name': 'Magic',
          'affixMin': 1,
          'affixMax': 2,
          'statMultiplier': 1.08,
          'specialEffectChance': 0,
        },
        {
          'id': 'rare',
          'name': 'Rare',
          'affixMin': 1,
          'affixMax': 1,
          'statMultiplier': 1.18,
          'specialEffectChance': 0.02,
        },
      ],
    }),
    _file('assets/data/drop_pools.json', {
      'schemaVersion': 1,
      'drop_pools': [
        {
          'id': 'drop_chapter_1',
          'name': 'Chapter 1',
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
