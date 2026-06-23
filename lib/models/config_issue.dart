import 'config_load_error.dart';
import 'config_validation_error.dart';

enum ConfigIssueSource {
  load,
  validation,
}

class ConfigIssue {
  const ConfigIssue({
    required this.source,
    required this.assetPath,
    required this.code,
    required this.message,
  });

  factory ConfigIssue.fromLoadError(ConfigLoadError error) {
    return ConfigIssue(
      source: ConfigIssueSource.load,
      assetPath: error.assetPath,
      code: error.type.name,
      message: error.message,
    );
  }

  factory ConfigIssue.fromValidationError(ConfigValidationError error) {
    return ConfigIssue(
      source: ConfigIssueSource.validation,
      assetPath: error.assetPath,
      code: error.code.name,
      message: error.message,
    );
  }

  final ConfigIssueSource source;
  final String assetPath;
  final String code;
  final String message;

  Map<String, Object?> toJson() {
    return {
      'source': source.name,
      'assetPath': assetPath,
      'code': code,
      'message': message,
    };
  }
}
