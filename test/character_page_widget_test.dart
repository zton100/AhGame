import 'package:abyss_relic/core/save/player_save_provider.dart';
import 'package:abyss_relic/core/theme/app_theme.dart';
import 'package:abyss_relic/features/character/character_page.dart';
import 'package:abyss_relic/models/data_file_meta.dart';
import 'package:abyss_relic/models/equipment_instance.dart';
import 'package:abyss_relic/models/equipment_loadout.dart';
import 'package:abyss_relic/models/equipment_template.dart';
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
  testWidgets('CharacterPage shows exile from a new save', (tester) async {
    final saveService = SaveService(store: InMemorySaveStore());

    await tester.pumpWidget(_app(saveService: saveService));
    await tester.pumpAndSettle();

    expect(find.text('角色'), findsOneWidget);
    expect(find.text('Exile'), findsOneWidget);
    expect(find.text('等级'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    expect(find.text('成长总览'), findsOneWidget);
    expect(find.textContaining('下一步建议'), findsOneWidget);
  });

  testWidgets('CharacterPage final attack increases with equipped weapon',
      (tester) async {
    final saveService = SaveService(store: InMemorySaveStore());
    await saveService.save(SaveData.newGame().copyWith(
      inventory: inventorySaveFromState(InventoryState(
        equipmentInstanceIds: const ['eq_weapon'],
        equipmentInstances: {'eq_weapon': _weapon()},
        equipmentLoadout: EquipmentLoadout.empty().equip(
          EquipmentSlot.mainWeapon,
          'eq_weapon',
        ),
      )),
    ));

    await tester.pumpWidget(_app(saveService: saveService));
    await tester.pumpAndSettle();

    expect(find.text('基础属性'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('最终属性'), 200);
    expect(find.text('最终属性'), findsOneWidget);
    expect(find.text('18'), findsWidgets);
    expect(find.text('30'), findsWidgets);
    expect(find.textContaining('已穿戴装备'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Rusted Blade'),
      200,
    );
    expect(find.textContaining('Rusted Blade'), findsOneWidget);
  });

  testWidgets('CharacterPage shows growth guidance', (tester) async {
    final saveService = SaveService(store: InMemorySaveStore());

    await tester.pumpWidget(_app(saveService: saveService));
    await tester.pumpAndSettle();

    expect(find.text('成长建议'), findsOneWidget);
    expect(find.text('下一步：运行 10 场战斗'), findsOneWidget);
  });

  testWidgets('CharacterPage warns when loadout instance is missing',
      (tester) async {
    final saveService = SaveService(store: InMemorySaveStore());
    await saveService.save(SaveData.newGame().copyWith(
      inventory: inventorySaveFromState(InventoryState(
        equipmentInstanceIds: const [],
        equipmentLoadout: EquipmentLoadout.empty().equip(
          EquipmentSlot.mainWeapon,
          'missing_eq',
        ),
      )),
    ));

    await tester.pumpWidget(_app(saveService: saveService));
    await tester.pumpAndSettle();

    expect(find.textContaining('已穿戴装备实例不存在'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('missing_eq（缺失）'),
      200,
    );
    expect(find.textContaining('missing_eq（缺失）'), findsOneWidget);
  });

  testWidgets('CharacterPage upgrades active skill and saves level',
      (tester) async {
    final saveService = SaveService(store: InMemorySaveStore());
    await saveService.save(SaveData.newGame().copyWith(
      inventory: const InventorySave(
        equipmentInstanceIds: [],
        materials: [MaterialStack(materialId: 'gold', quantity: 50)],
      ),
    ));

    await tester.pumpWidget(_app(saveService: saveService));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('技能'), 200);
    expect(find.text('技能'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -260));
    await tester.pumpAndSettle();
    expect(find.text('升级技能'), findsOneWidget);

    await tester.tap(find.text('升级技能'));
    await tester.pumpAndSettle();

    final save = await saveService.loadOrCreate();
    expect(save.playerProgress.skillLevels['toxic_slash'], 2);
    expect(find.textContaining('技能已升级到 2 级'), findsOneWidget);
  });
}

Widget _app({required SaveService saveService}) {
  return ProviderScope(
    overrides: [
      saveServiceProvider.overrideWithValue(saveService),
      gameDatabaseLoadProvider.overrideWith((ref) async {
        return GameDatabaseLoadResult(database: _database(), errors: const []);
      }),
    ],
    child: MaterialApp(
      theme: AppTheme.dark(),
      home: const Scaffold(body: CharacterPage()),
    ),
  );
}

EquipmentInstance _weapon() {
  return EquipmentInstance(
    instanceId: 'eq_weapon',
    templateId: 'rusted_blade',
    qualityId: 'rare',
    level: 1,
    createdAt: DateTime.utc(2026, 6, 24),
    rolledBaseStats: const [
      RolledBaseStat(stat: 'attack', value: 12),
    ],
    rolledAffixes: const [],
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
      'affixes': [],
    }),
    _file('assets/data/skills.json', {
      'schemaVersion': 1,
      'skills': [
        {
          'id': 'toxic_slash',
          'name': '毒刃',
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
