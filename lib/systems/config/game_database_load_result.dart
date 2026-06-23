import '../../models/config_load_error.dart';
import '../../models/game_database_summary.dart';
import 'game_database.dart';

class GameDatabaseLoadResult {
  const GameDatabaseLoadResult({
    required this.database,
    required this.errors,
  });

  final GameDatabase database;
  final List<ConfigLoadError> errors;

  bool get hasErrors => errors.isNotEmpty;

  GameDatabaseSummary get summary {
    return GameDatabaseSummary(
      fileCount: database.fileCount,
      recordCount: database.recordCount,
      errorCount: errors.length,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'summary': summary.toJson(),
      'errors': errors.map((error) => error.toJson()).toList(),
      'database': database.toJson(),
    };
  }
}
