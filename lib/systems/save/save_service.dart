import '../../models/save_data.dart';
import 'backup_service.dart';
import 'save_migration_service.dart';
import 'save_store.dart';

class SaveService {
  const SaveService({
    required SaveStore store,
    SaveMigrationService migrationService = const SaveMigrationService(),
    BackupService? backupService,
  })  : _store = store,
        _migrationService = migrationService,
        _backupService = backupService;

  final SaveStore _store;
  final SaveMigrationService _migrationService;
  final BackupService? _backupService;

  Future<SaveData> loadOrCreate() async {
    final json = await _tryRead(_store);
    if (json != null) {
      final saveData = _tryMigrate(json);
      if (saveData != null) {
        return saveData;
      }
    }

    final backupJson = await _backupService?.readBackup();
    if (backupJson != null) {
      final backupSaveData = _tryMigrate(backupJson);
      if (backupSaveData != null) {
        await saveData(backupSaveData);
        return backupSaveData;
      }
    }

    if (json == null) {
      final save = SaveData.newGame();
      await saveData(save);
      return save;
    }

    final save = SaveData.newGame();
    await saveData(save);
    return save;
  }

  Future<void> save(SaveData saveData) {
    return this.saveData(saveData);
  }

  Future<void> saveData(SaveData saveData) async {
    final existing = await _tryRead(_store);
    if (existing != null) {
      await _backupService?.writeBackup(existing);
    }

    final updated = saveData.copyWith(lastSavedAt: DateTime.now().toUtc());
    final json = updated.toJson();
    await _store.write(json);

    if (existing == null) {
      await _backupService?.writeBackup(json);
    }
  }

  Future<void> delete() async {
    await _store.delete();
    await _backupService?.deleteBackup();
  }

  Future<Map<String, Object?>?> _tryRead(SaveStore store) async {
    try {
      return await store.read();
    } on Object {
      return null;
    }
  }

  SaveData? _tryMigrate(Map<String, Object?> json) {
    try {
      return _migrationService.migrate(json).saveData;
    } on Object {
      return null;
    }
  }
}
