import 'dart:io';

import 'package:abyss_relic/models/affix_config.dart';
import 'package:abyss_relic/models/equipment_instance.dart';
import 'package:abyss_relic/models/save_data.dart';
import 'package:abyss_relic/systems/save/auto_save_service.dart';
import 'package:abyss_relic/systems/save/backup_service.dart';
import 'package:abyss_relic/systems/save/app_lifecycle_auto_save_observer.dart';
import 'package:abyss_relic/systems/save/hive_save_store.dart';
import 'package:abyss_relic/systems/save/in_memory_save_store.dart';
import 'package:abyss_relic/systems/save/save_migration_service.dart';
import 'package:abyss_relic/systems/save/save_service.dart';
import 'package:abyss_relic/systems/save/save_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';

void main() {
  test('SaveService creates a new save when storage is empty', () async {
    final service = SaveService(store: InMemorySaveStore());

    final save = await service.loadOrCreate();

    expect(save.saveVersion, SaveData.currentVersion);
    expect(save.playerProgress.currentClassId, 'exile');
    expect(save.inventory.equipmentInstanceIds, isEmpty);
  });

  test('SaveService saves and loads existing save data', () async {
    final store = InMemorySaveStore();
    final service = SaveService(store: store);
    final initial = SaveData.newGame(now: DateTime.utc(2026, 6, 23));
    final changed = initial.copyWith(
      playerProgress: initial.playerProgress.copyWith(
        level: 7,
        currentClassId: 'sanctifier',
      ),
    );

    await service.save(changed);
    final loaded = await service.loadOrCreate();

    expect(loaded.playerProgress.level, 7);
    expect(loaded.playerProgress.currentClassId, 'sanctifier');
  });

  test('SaveService preserves full equipment instances across reload',
      () async {
    final store = InMemorySaveStore();
    final service = SaveService(store: store);
    final equipment = EquipmentInstance(
      instanceId: 'eq_1',
      templateId: 'rusted_blade',
      qualityId: 'rare',
      level: 5,
      createdAt: DateTime.utc(2026, 6, 24),
      rolledBaseStats: const [RolledBaseStat(stat: 'attack', value: 12)],
      rolledAffixes: const [
        RolledAffix(
          affixId: 'aff_poison_damage',
          rollValue: 0.12,
          exclusiveGroup: 'element_damage',
        ),
      ],
    );
    final initial = SaveData.newGame(now: DateTime.utc(2026, 6, 24));
    final changed = initial.copyWith(
      inventory: initial.inventory.copyWith(
        equipmentInstanceIds: ['eq_1'],
        equipmentInstances: {'eq_1': equipment},
      ),
    );

    await service.save(changed);
    final loaded = await service.loadOrCreate();
    final restored = loaded.inventory.equipmentInstances['eq_1']!;

    expect(loaded.inventory.equipmentInstanceIds, ['eq_1']);
    expect(restored.templateId, 'rusted_blade');
    expect(restored.qualityId, 'rare');
    expect(restored.rolledBaseStats.single.value, 12);
    expect(restored.rolledAffixes.single.affixId, 'aff_poison_damage');
    expect(restored.rolledAffixes.single.rollValue, 0.12);
  });

  test('SaveService stores previous save data as a backup before overwrite',
      () async {
    final store = InMemorySaveStore();
    final backupStore = InMemorySaveStore();
    final service = SaveService(
      store: store,
      backupService: BackupService(backupStore: backupStore),
    );
    final initial = SaveData.newGame(now: DateTime.utc(2026, 6, 23)).copyWith(
      playerProgress: const PlayerProgress(
        currentClassId: 'exile',
        level: 2,
        experience: 10,
      ),
    );
    final changed = initial.copyWith(
      playerProgress: initial.playerProgress.copyWith(level: 4),
    );

    await service.save(initial);
    await service.save(changed);

    final backup = SaveData.fromJson((await backupStore.read())!);
    expect(backup.playerProgress.level, 2);
  });

  test('SaveService restores from backup when primary save cannot be read',
      () async {
    final backupStore = InMemorySaveStore();
    final backupSave =
        SaveData.newGame(now: DateTime.utc(2026, 6, 23)).copyWith(
      playerProgress: const PlayerProgress(
        currentClassId: 'necrospeaker',
        level: 12,
        experience: 940,
      ),
    );
    await backupStore.write(backupSave.toJson());

    final service = SaveService(
      store: _UnreadableSaveStore(),
      backupService: BackupService(backupStore: backupStore),
    );

    final loaded = await service.loadOrCreate();

    expect(loaded.playerProgress.currentClassId, 'necrospeaker');
    expect(loaded.playerProgress.level, 12);
  });

  test('SaveService deletes save data and recreates a new save', () async {
    final service = SaveService(store: InMemorySaveStore());
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 23));

    await service.save(save.copyWith(
      playerProgress: save.playerProgress.copyWith(level: 9),
    ));
    await service.delete();
    final loaded = await service.loadOrCreate();

    expect(loaded.playerProgress.level, 1);
  });

  test('SaveMigrationService migrates legacy v1 saves to current version', () {
    final migration = SaveMigrationService();

    final result = migration.migrate({
      'saveVersion': 1,
      'createdAt': '2026-06-23T00:00:00.000Z',
      'lastSavedAt': '2026-06-23T00:10:00.000Z',
      'playerProgress': {
        'currentClassId': 'exile',
        'level': 3,
        'experience': 120,
      },
      'inventory': {
        'equipmentInstanceIds': ['eq_1'],
      },
      'settings': {
        'soundEnabled': false,
        'hapticsEnabled': true,
      },
    });

    expect(result.success, isTrue);
    expect(result.saveData.saveVersion, SaveData.currentVersion);
    expect(result.saveData.playerProgress.level, 3);
    expect(result.saveData.inventory.equipmentInstanceIds, ['eq_1']);
    expect(result.warnings, [
      'Migrated saveVersion 1 to 2.',
      'Migrated saveVersion 2 to 3.',
      'Migrated saveVersion 3 to 4.',
    ]);
  });

  test('SaveMigrationService migrates v2 saves with last exit placeholder', () {
    final migration = SaveMigrationService();

    final result = migration.migrate({
      'saveVersion': 2,
      'createdAt': '2026-06-23T00:00:00.000Z',
      'lastSavedAt': '2026-06-23T00:10:00.000Z',
      'playerProgress': {
        'currentClassId': 'exile',
        'level': 3,
        'experience': 120,
      },
      'inventory': {
        'equipmentInstanceIds': ['eq_1'],
      },
      'settings': {
        'soundEnabled': false,
        'hapticsEnabled': true,
      },
    });

    expect(result.success, isTrue);
    expect(result.saveData.saveVersion, SaveData.currentVersion);
    expect(result.saveData.lastExitAt, isNull);
    expect(result.warnings, [
      'Migrated saveVersion 2 to 3.',
      'Migrated saveVersion 3 to 4.',
    ]);
  });

  test('HiveSaveStore persists save data across store instances', () async {
    final directory = await Directory.systemTemp.createTemp('abyss_save_test_');
    Hive.init(directory.path);
    final box = await Hive.openBox<dynamic>('saves');

    try {
      final firstService = SaveService(
        store: HiveSaveStore(box: box),
      );
      final initial = SaveData.newGame(now: DateTime.utc(2026, 6, 23)).copyWith(
        playerProgress: const PlayerProgress(
          currentClassId: 'frost_ranger',
          level: 5,
          experience: 310,
        ),
      );

      await firstService.save(initial);

      final secondService = SaveService(
        store: HiveSaveStore(box: box),
      );
      final loaded = await secondService.loadOrCreate();

      expect(loaded.playerProgress.currentClassId, 'frost_ranger');
      expect(loaded.playerProgress.level, 5);
    } finally {
      await box.close();
      await Hive.close();
      await directory.delete(recursive: true);
    }
  });

  test('AutoSaveService records last exit time and saves immediately',
      () async {
    final store = InMemorySaveStore();
    final saveService = SaveService(store: store);
    final now = DateTime.utc(2026, 6, 23, 12, 30);
    final autoSave = AutoSaveService(
      saveService: saveService,
      now: () => now,
    );
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 23));

    final result = await autoSave.recordAppExit(save);
    final loaded = await saveService.loadOrCreate();

    expect(result.status, AutoSaveStatus.saved);
    expect(loaded.lastExitAt, now);
  });

  test('AutoSaveService throttles repeated action saves', () async {
    final saveService = SaveService(store: InMemorySaveStore());
    var now = DateTime.utc(2026, 6, 23, 12, 30);
    final autoSave = AutoSaveService(
      saveService: saveService,
      now: () => now,
      minimumInterval: const Duration(seconds: 10),
    );
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 23));

    final first = await autoSave.saveAfterAction(save, reason: 'equip_item');
    now = now.add(const Duration(seconds: 3));
    final second = await autoSave.saveAfterAction(save, reason: 'equip_item');

    expect(first.status, AutoSaveStatus.saved);
    expect(second.status, AutoSaveStatus.skipped);
    expect(second.nextAllowedAt, DateTime.utc(2026, 6, 23, 12, 30, 10));
  });

  test('AutoSaveService exposes save errors for Debug surfaces', () async {
    final autoSave = AutoSaveService(
      saveService: SaveService(store: _FailingWriteSaveStore()),
      now: () => DateTime.utc(2026, 6, 23, 12, 30),
    );
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 23));

    final result = await autoSave.saveAfterAction(save, reason: 'equip_item');

    expect(result.status, AutoSaveStatus.failed);
    expect(result.error, contains('Cannot write save.'));
    expect(autoSave.lastError, contains('Cannot write save.'));
  });

  test('AppLifecycleAutoSaveObserver saves when app enters background',
      () async {
    final store = InMemorySaveStore();
    final saveService = SaveService(store: store);
    final now = DateTime.utc(2026, 6, 23, 13);
    final observer = AppLifecycleAutoSaveObserver(
      autoSaveService: AutoSaveService(
        saveService: saveService,
        now: () => now,
      ),
      loadCurrentSave: () async => SaveData.newGame(
        now: DateTime.utc(2026, 6, 23),
      ),
    );

    final result = await observer.handleLifecycleState(
      AppLifecycleState.paused,
    );
    final loaded = await saveService.loadOrCreate();

    expect(result?.status, AutoSaveStatus.saved);
    expect(loaded.lastExitAt, now);
  });
}

class _UnreadableSaveStore implements SaveStore {
  @override
  Future<Map<String, Object?>?> read() {
    throw const FormatException('Corrupted primary save.');
  }

  @override
  Future<void> write(Map<String, Object?> json) async {}

  @override
  Future<void> delete() async {}
}

class _FailingWriteSaveStore implements SaveStore {
  @override
  Future<Map<String, Object?>?> read() async {
    return null;
  }

  @override
  Future<void> write(Map<String, Object?> json) {
    throw StateError('Cannot write save.');
  }

  @override
  Future<void> delete() async {}
}
