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

    if (version == 3) {
      final playerProgress = Map<String, Object?>.from(
        migrated['playerProgress'] as Map? ?? const {},
      );
      playerProgress['currentChapterId'] =
          playerProgress['currentChapterId'] ?? PlayerProgress.defaultChapterId;
      playerProgress['currentStageId'] =
          playerProgress['currentStageId'] ?? PlayerProgress.defaultStageId;
      migrated['playerProgress'] = playerProgress;
      version = 4;
      migrated['saveVersion'] = version;
      warnings.add('Migrated saveVersion 3 to 4.');
    }

    if (version == 4) {
      final inventory = Map<String, Object?>.from(
        migrated['inventory'] as Map? ?? const {},
      );
      inventory['autoSalvageConfig'] = inventory['autoSalvageConfig'] ??
          const {
            'enabled': false,
            'minQualityToKeep': 'rare',
            'keepLegendaryOrAbove': true,
            'keepLocked': true,
            'keepEquipped': true,
            'minBuildMatchScoreToKeep': 60,
            'allowedQualityIdsToSalvage': <String>[],
            'maxInventoryUsageBeforeSalvage': null,
          };
      migrated['inventory'] = inventory;
      version = 5;
      migrated['saveVersion'] = version;
      warnings.add('Migrated saveVersion 4 to 5.');
    }

    if (version == 5) {
      final playerProgress = Map<String, Object?>.from(
        migrated['playerProgress'] as Map? ?? const {},
      );
      playerProgress['skillLevels'] = playerProgress['skillLevels'] ?? {};
      migrated['playerProgress'] = playerProgress;
      version = 6;
      migrated['saveVersion'] = version;
      warnings.add('Migrated saveVersion 5 to 6.');
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
