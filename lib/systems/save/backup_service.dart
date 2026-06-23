import 'save_store.dart';

class BackupService {
  const BackupService({required SaveStore backupStore})
      : _backupStore = backupStore;

  final SaveStore _backupStore;

  Future<Map<String, Object?>?> readBackup() {
    return _backupStore.read();
  }

  Future<void> writeBackup(Map<String, Object?> json) {
    return _backupStore.write(json);
  }

  Future<void> deleteBackup() {
    return _backupStore.delete();
  }
}
