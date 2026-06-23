import '../../models/migration_result.dart';
import '../../models/save_data.dart';

class SaveMigrationService {
  const SaveMigrationService();

  MigrationResult migrate(Map<String, Object?> json) {
    var version = json['saveVersion'] as int? ?? 1;
    final migrated = Map<String, Object?>.from(json);
    final warnings = <String>[];

    if (version == SaveData.currentVersion) {
      return MigrationResult(
        success: true,
        saveData: SaveData.fromJson(migrated),
      );
    }

    if (version == 1) {
      migrated['settings'] = migrated['settings'] ??
          const {
            'soundEnabled': true,
            'hapticsEnabled': true,
          };
      version = 2;
      migrated['saveVersion'] = version;
      warnings.add('Migrated saveVersion 1 to 2.');
    }

    if (version == 2) {
      migrated['lastExitAt'] = migrated['lastExitAt'];
      version = 3;
      migrated['saveVersion'] = version;
      warnings.add('Migrated saveVersion 2 to 3.');
    }

    if (version == SaveData.currentVersion) {
      return MigrationResult(
        success: true,
        saveData: SaveData.fromJson(migrated),
        warnings: warnings,
      );
    }

    throw StateError('Unsupported saveVersion: $version');
  }
}
