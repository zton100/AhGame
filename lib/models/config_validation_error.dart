enum ConfigValidationSeverity {
  warning,
  error,
}

enum ConfigValidationCode {
  missingSchemaVersion,
  missingRecords,
  missingRequiredField,
  duplicateId,
  invalidReference,
}

class ConfigValidationError {
  const ConfigValidationError({
    required this.assetPath,
    required this.code,
    required this.message,
    this.severity = ConfigValidationSeverity.error,
    this.tableName,
    this.recordId,
    this.field,
  });

  factory ConfigValidationError.fromJson(Map<String, Object?> json) {
    return ConfigValidationError(
      assetPath: json['assetPath'] as String,
      code: ConfigValidationCode.values.byName(json['code'] as String),
      message: json['message'] as String,
      severity: ConfigValidationSeverity.values.byName(
        json['severity'] as String,
      ),
      tableName: json['tableName'] as String?,
      recordId: json['recordId'] as String?,
      field: json['field'] as String?,
    );
  }

  final String assetPath;
  final ConfigValidationCode code;
  final ConfigValidationSeverity severity;
  final String message;
  final String? tableName;
  final String? recordId;
  final String? field;

  Map<String, Object?> toJson() {
    return {
      'assetPath': assetPath,
      'code': code.name,
      'severity': severity.name,
      'message': message,
      'tableName': tableName,
      'recordId': recordId,
      'field': field,
    };
  }
}
