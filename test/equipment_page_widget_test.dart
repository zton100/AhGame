import 'package:abyss_relic/core/save/player_save_provider.dart';
import 'package:abyss_relic/core/theme/app_theme.dart';
import 'package:abyss_relic/features/equipment/equipment_page.dart';
import 'package:abyss_relic/features/equipment/equipment_page_view_model.dart';
import 'package:abyss_relic/models/affix_config.dart';
import 'package:abyss_relic/models/auto_salvage_config.dart';
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
  testWidgets('EquipmentPage shows empty inventory from an empty save',
      (tester) async {
    final saveService = SaveService(store: InMemorySaveStore());

    await tester.pumpWidget(_app(saveService: saveService));
    await tester.pumpAndSettle();

    expect(find.text('背包暂无装备'), findsOneWidget);
    expect(find.text('击败敌人后获得的装备会出现在这里。'), findsOneWidget);
    expect(find.text('Enable Auto Salvage'), findsOneWidget);
    expect(find.text('Keep Rare+'), findsOneWidget);
    expect(find.text('Enhance recommended equipped'), findsOneWidget);
    expect(find.text('Equip recommended upgrade'), findsOneWidget);
  });

  testWidgets('EquipmentPage generates test equipment through SaveData',
      (tester) async {
    final saveService = SaveService(store: InMemorySaveStore());

    await tester.pumpWidget(_app(saveService: saveService));
    await tester.pumpAndSettle();

    await tester.tap(find.text('生成测试装备到背包'));
    await tester.pumpAndSettle();

    expect(find.text('Rusted Blade'), findsOneWidget);
    expect(find.textContaining('Rare'), findsWidgets);
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
    expect(find.textContaining('Rare'), findsWidgets);
    expect(find.textContaining('BD'), findsWidgets);
    expect(find.textContaining('推荐 poison'), findsOneWidget);

    await tester.tap(find.text('Poison Blade'));
    await tester.pumpAndSettle();

    expect(find.text('基础属性'), findsOneWidget);
    expect(find.text('词缀'), findsOneWidget);
    expect(find.text('BD 匹配'), findsOneWidget);
    expect(find.textContaining('Poison Damage'), findsWidgets);
    expect(find.text('穿戴'), findsOneWidget);
    expect(find.text('锁定'), findsOneWidget);
    expect(find.text('分解'), findsOneWidget);
    expect(find.textContaining('matchedTags'), findsOneWidget);
  });

  testWidgets('EquipmentPage equips equipment and saves loadout',
      (tester) async {
    final saveService = SaveService(store: InMemorySaveStore());
    await _savePoisonBlade(saveService);

    await tester.pumpWidget(_app(saveService: saveService));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Poison Blade'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('穿戴'));
    await tester.pumpAndSettle();

    final save = await saveService.loadOrCreate();
    expect(
      save.inventory.equipmentLoadout.equippedInstanceId(
        EquipmentSlot.mainWeapon,
      ),
      'eq_poison_blade',
    );
  });

  testWidgets('EquipmentPage scores equipment with current save class',
      (tester) async {
    final saveService = SaveService(store: InMemorySaveStore());
    await saveService.save(SaveData.newGame().copyWith(
      playerProgress: const PlayerProgress(
        currentClassId: 'necrospeaker',
        level: 1,
        experience: 0,
      ),
      inventory: inventorySaveFromState(InventoryState(
        equipmentInstanceIds: const ['eq_scepter'],
        equipmentInstances: {'eq_scepter': _summonEquipment()},
      )),
    ));

    await tester.pumpWidget(_app(saveService: saveService));
    await tester.pumpAndSettle();

    expect(find.text('Grave Scepter'), findsOneWidget);
  });

  test('EquipmentPageViewModelFactory uses the supplied class id', () {
    final inventory = InventoryState(
      equipmentInstanceIds: const ['eq_scepter'],
      equipmentInstances: {'eq_scepter': _summonEquipment()},
    );
    final necroViewModel = const EquipmentPageViewModelFactory().create(
      inventory: inventory,
      database: _database(),
      classId: 'necrospeaker',
    );
    final exileViewModel = const EquipmentPageViewModelFactory().create(
      inventory: inventory,
      database: _database(),
      classId: 'exile',
    );

    expect(necroViewModel.items.single.card.matchedTags, contains('summon'));
    expect(exileViewModel.items.single.card.matchedTags,
        isNot(contains('summon')));
  });

  testWidgets('EquipmentPage blocks salvaging locked equipment',
      (tester) async {
    final saveService = SaveService(store: InMemorySaveStore());
    await _savePoisonBlade(saveService, locked: true);

    await tester.pumpWidget(_app(saveService: saveService));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Poison Blade'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('分解'));
    await tester.pumpAndSettle();

    final save = await saveService.loadOrCreate();
    expect(save.inventory.equipmentInstanceIds, ['eq_poison_blade']);
    expect(save.inventory.equipmentInstances.keys, ['eq_poison_blade']);
    expect(find.textContaining('已锁定装备不能分解'), findsOneWidget);
  });

  testWidgets('EquipmentPage blocks salvaging equipped equipment',
      (tester) async {
    final saveService = SaveService(store: InMemorySaveStore());
    await _savePoisonBlade(
      saveService,
      loadout: EquipmentLoadout.empty().equip(
        EquipmentSlot.mainWeapon,
        'eq_poison_blade',
      ),
    );

    await tester.pumpWidget(_app(saveService: saveService));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Poison Blade'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('分解'));
    await tester.pumpAndSettle();

    final save = await saveService.loadOrCreate();
    expect(save.inventory.equipmentInstanceIds, ['eq_poison_blade']);
    expect(save.inventory.equipmentInstances.keys, ['eq_poison_blade']);
    expect(find.textContaining('已穿戴装备不能分解'), findsOneWidget);
  });

  testWidgets('EquipmentPage salvages equipment into materials',
      (tester) async {
    final saveService = SaveService(store: InMemorySaveStore());
    await _savePoisonBlade(saveService);

    await tester.pumpWidget(_app(saveService: saveService));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Poison Blade'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('分解'));
    await tester.pumpAndSettle();

    final save = await saveService.loadOrCreate();
    expect(save.inventory.equipmentInstanceIds, isEmpty);
    expect(save.inventory.equipmentInstances, isEmpty);
    expect(save.inventory.materials.single.materialId, 'salvage_dust');
    expect(save.inventory.materials.single.quantity, 1);
  });

  testWidgets('EquipmentPage enhances equipment and persists +1',
      (tester) async {
    final saveService = SaveService(store: InMemorySaveStore());
    await _savePoisonBlade(
      saveService,
      materials: const [
        MaterialStack(materialId: 'gold', quantity: 20),
        MaterialStack(materialId: 'salvage_dust', quantity: 2),
      ],
    );

    await tester.pumpWidget(_app(saveService: saveService));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Poison Blade'));
    await tester.pumpAndSettle();

    expect(find.text('Enhance Level: +0'), findsOneWidget);
    expect(find.text('Enhance'), findsOneWidget);

    await tester.tap(find.text('Enhance'));
    await tester.pumpAndSettle();

    final save = await saveService.loadOrCreate();
    expect(
        save.inventory.equipmentInstances['eq_poison_blade']!.enhanceLevel, 1);
    expect(find.textContaining('Enhanced to +1'), findsOneWidget);
    expect(find.text('Poison Blade +1'), findsOneWidget);
  });

  testWidgets('EquipmentPage batch salvages filtered low value equipment',
      (tester) async {
    final saveService = SaveService(store: InMemorySaveStore());
    await saveService.save(SaveData.newGame().copyWith(
      inventory: InventorySave(
        equipmentInstanceIds: const ['eq_normal_blade'],
        equipmentInstances: {'eq_normal_blade': _normalEquipment()},
        autoSalvageConfig: const AutoSalvageConfig(
          enabled: true,
          minQualityToKeep: 'rare',
        ),
      ),
    ));

    await tester.pumpWidget(_app(saveService: saveService));
    await tester.pumpAndSettle();

    expect(find.text('Plain Blade'), findsOneWidget);
    expect(find.text('Salvage filtered low-value'), findsOneWidget);

    await tester.tap(find.text('Salvage filtered low-value'));
    await tester.pumpAndSettle();

    final save = await saveService.loadOrCreate();
    expect(save.inventory.equipmentInstanceIds, isEmpty);
    expect(save.inventory.equipmentInstances, isEmpty);
    expect(save.inventory.materials.single.materialId, 'salvage_dust');
    expect(save.inventory.materials.single.quantity, 1);
    expect(find.textContaining('Auto salvaged 1'), findsOneWidget);
  });

  test('PlayerSaveController fails when equipping missing equipment', () async {
    final container = ProviderContainer(
      overrides: [
        saveServiceProvider.overrideWithValue(
          SaveService(store: InMemorySaveStore()),
        ),
        gameDatabaseLoadProvider.overrideWith((ref) async {
          return GameDatabaseLoadResult(
              database: _database(), errors: const []);
        }),
      ],
    );
    addTearDown(container.dispose);

    await container.read(playerSaveProvider.future);

    expect(
      () => container.read(playerSaveProvider.notifier).equipEquipment(
            database: _database(),
            instanceId: 'missing_eq',
          ),
      throwsA(isA<StateError>()),
    );
  });
}

Future<void> _savePoisonBlade(
  SaveService saveService, {
  bool locked = false,
  EquipmentLoadout loadout = const EquipmentLoadout.empty(),
  List<MaterialStack> materials = const [],
}) {
  return saveService.save(SaveData.newGame().copyWith(
    inventory: inventorySaveFromState(InventoryState(
      equipmentInstanceIds: const ['eq_poison_blade'],
      equipmentInstances: {'eq_poison_blade': _equipment()},
      equipmentLoadout: loadout,
      materials: materials,
      lockedEquipmentInstanceIds: locked ? const ['eq_poison_blade'] : const [],
    )),
  ));
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

EquipmentInstance _summonEquipment() {
  return EquipmentInstance(
    instanceId: 'eq_scepter',
    templateId: 'grave_scepter',
    qualityId: 'rare',
    level: 1,
    createdAt: DateTime.utc(2026, 6, 24),
    rolledBaseStats: const [
      RolledBaseStat(stat: 'attack', value: 12),
    ],
    rolledAffixes: const [],
  );
}

EquipmentInstance _normalEquipment() {
  return EquipmentInstance(
    instanceId: 'eq_normal_blade',
    templateId: 'plain_blade',
    qualityId: 'normal',
    level: 1,
    createdAt: DateTime.utc(2026, 6, 24),
    rolledBaseStats: const [
      RolledBaseStat(stat: 'attack', value: 2),
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
        {
          'id': 'necrospeaker',
          'name': 'Necrospeaker',
          'tags': ['summon', 'undead'],
          'baseStats': {'hp': 90, 'attack': 14, 'armor': 4},
          'growth': {'hp': 8, 'attack': 2, 'armor': 1},
        },
      ],
    }),
    _file('assets/data/equipment_templates.json', {
      'schemaVersion': 1,
      'equipment_templates': [
        {
          'id': 'plain_blade',
          'name': 'Plain Blade',
          'slot': 'main_weapon',
          'allowedClasses': ['exile'],
          'minLevel': 1,
          'qualityPool': ['normal'],
          'baseStats': [
            {'stat': 'attack', 'min': 1, 'max': 3},
          ],
          'affixRules': {
            'prefixMin': 0,
            'prefixMax': 0,
            'suffixMin': 0,
            'suffixMax': 0,
            'allowedTags': <String>[],
          },
        },
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
        {
          'id': 'grave_scepter',
          'name': 'Grave Scepter',
          'slot': 'main_weapon',
          'allowedClasses': ['necrospeaker'],
          'minLevel': 1,
          'qualityPool': ['rare'],
          'baseStats': [
            {'stat': 'attack', 'min': 6, 'max': 12},
          ],
          'affixRules': {
            'prefixMin': 0,
            'prefixMax': 1,
            'suffixMin': 0,
            'suffixMax': 1,
            'allowedTags': ['summon', 'curse'],
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
    _file('assets/data/enhancement_config.json', {
      'schemaVersion': 1,
      'enhancement_config': [
        {
          'id': 'default',
          'maxLevel': 10,
          'dustCostByLevel': [1, 2, 3, 5, 8, 12, 18, 25, 35, 50],
          'goldCostByLevel': [10, 20, 35, 55, 80, 120, 180, 260, 360, 500],
          'statMultiplierByLevel': [
            1.05,
            1.10,
            1.16,
            1.22,
            1.30,
            1.38,
            1.47,
            1.57,
            1.68,
            1.80,
          ],
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
