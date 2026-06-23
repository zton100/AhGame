import '../../models/config_validation_error.dart';
import '../../models/loaded_data_file.dart';

class ConfigValidator {
  const ConfigValidator();

  List<ConfigValidationError> validateFiles(Iterable<LoadedDataFile> files) {
    return [
      for (final file in files) ...validateFile(file),
    ];
  }

  List<ConfigValidationError> validateFile(LoadedDataFile file) {
    final errors = <ConfigValidationError>[];
    final json = file.json;

    if (json['schemaVersion'] is! int) {
      errors.add(
        ConfigValidationError(
          assetPath: file.meta.assetPath,
          code: ConfigValidationCode.missingSchemaVersion,
          field: 'schemaVersion',
          message: 'Config must include an integer schemaVersion.',
        ),
      );
    }

    final table = _findRecordTable(json);
    if (table == null) {
      if (json['id'] is String) {
        errors.addAll(_validateRecord(
          assetPath: file.meta.assetPath,
          tableName: _tableNameForFile(file.meta.assetPath),
          record: json,
          requiredFields: const ['id', 'displayName'],
        ));
      } else {
        errors.add(
          ConfigValidationError(
            assetPath: file.meta.assetPath,
            code: ConfigValidationCode.missingRecords,
            message: 'Config file must contain a root id or a record list.',
          ),
        );
      }

      return errors;
    }

    final seenIds = <String>{};
    final tableName = table.key;
    final records = table.value;

    for (final record in records.whereType<Map<String, Object?>>()) {
      errors.addAll(_validateRecord(
        assetPath: file.meta.assetPath,
        tableName: tableName,
        record: record,
      ));

      final id = record['id'];
      if (id is! String) {
        continue;
      }

      if (!seenIds.add(id)) {
        errors.add(
          ConfigValidationError(
            assetPath: file.meta.assetPath,
            code: ConfigValidationCode.duplicateId,
            tableName: tableName,
            recordId: id,
            field: 'id',
            message: 'Duplicate id "$id" in table "$tableName".',
          ),
        );
      }
    }

    return errors;
  }

  List<ConfigValidationError> _validateRecord({
    required String assetPath,
    required String tableName,
    required Map<String, Object?> record,
    List<String> requiredFields = const ['id', 'name'],
  }) {
    final errors = <ConfigValidationError>[];

    for (final field in requiredFields) {
      final value = record[field];
      if (value is String && value.trim().isNotEmpty) {
        continue;
      }

      errors.add(
        ConfigValidationError(
          assetPath: assetPath,
          code: ConfigValidationCode.missingRequiredField,
          tableName: tableName,
          recordId: record['id'] as String?,
          field: field,
          message: 'Record in "$tableName" must include "$field".',
        ),
      );
    }

    return errors;
  }

  MapEntry<String, List<Object?>>? _findRecordTable(
    Map<String, Object?> json,
  ) {
    for (final entry in json.entries) {
      if (entry.value is List<Object?>) {
        return MapEntry(entry.key, entry.value as List<Object?>);
      }
    }
    return null;
  }

  String _tableNameForFile(String assetPath) {
    final fileName = assetPath.split('/').last;
    return fileName.endsWith('.json')
        ? fileName.substring(0, fileName.length - '.json'.length)
        : fileName;
  }
}
