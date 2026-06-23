import '../../models/config_load_error.dart';
import '../../models/config_issue.dart';
import '../../models/config_validation_error.dart';
import '../../models/game_database_summary.dart';
import 'game_database.dart';

class GameDatabaseLoadResult {
  const GameDatabaseLoadResult({
    required this.database,
    required this.errors,
    this.validationErrors = const [],
  });

  final GameDatabase database;
  final List<ConfigLoadError> errors;
  final List<ConfigValidationError> validationErrors;

  bool get hasErrors => issues.isNotEmpty;

  List<ConfigIssue> get issues {
    return [
      ...errors.map(ConfigIssue.fromLoadError),
      ...validationErrors.map(ConfigIssue.fromValidationError),
    ];
  }

  GameDatabaseSummary get summary {
    return GameDatabaseSummary(
      fileCount: database.fileCount,
      recordCount: database.recordCount,
      errorCount: issues.length,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'summary': summary.toJson(),
      'errors': errors.map((error) => error.toJson()).toList(),
      'validationErrors': validationErrors.map((error) {
        return error.toJson();
      }).toList(),
      'database': database.toJson(),
    };
  }
}
