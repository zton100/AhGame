enum ConfigLoadErrorType {
  assetNotFound,
  invalidJson,
  invalidRoot,
  missingSchemaVersion,
  unexpected,
}

class ConfigLoadError {
  const ConfigLoadError({
    required this.assetPath,
    required this.type,
    required this.message,
  });

  factory ConfigLoadError.fromJson(Map<String, Object?> json) {
    return ConfigLoadError(
      assetPath: json['assetPath'] as String,
      type: ConfigLoadErrorType.values.byName(json['type'] as String),
      message: json['message'] as String,
    );
  }

  final String assetPath;
  final ConfigLoadErrorType type;
  final String message;

  Map<String, Object?> toJson() {
    return {
      'assetPath': assetPath,
      'type': type.name,
      'message': message,
    };
  }
}
