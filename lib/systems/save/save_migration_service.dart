import '../../models/migration_result.dart';
import '../../models/save_data.dart';

class SaveMigrationService {
  const SaveMigrationService();

  MigrationResult migrate(Map<String, Object?> json) {
    final version = json['saveVersion'] as int? ?? 1;

    if (version == SaveData.currentVersion) {
      return MigrationResult(
        success: true,
        saveData: SaveData.fromJson(json),
      );
    }

    if (version == 1) {
      final migrated = Map<String, Object?>.from(json);
      migrated['saveVersion'] = SaveData.currentVersion;
      migrated['settings'] = migrated['settings'] ??
          const {
            'soundEnabled': true,
            'hapticsEnabled': true,
          };

      return MigrationResult(
        success: true,
        saveData: SaveData.fromJson(migrated),
        warnings: const ['Migrated saveVersion 1 to current version.'],
      );
    }

    throw StateError('Unsupported saveVersion: $version');
  }
}
