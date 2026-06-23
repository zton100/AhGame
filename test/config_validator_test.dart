import 'package:abyss_relic/models/config_validation_error.dart';
import 'package:abyss_relic/models/data_file_meta.dart';
import 'package:abyss_relic/models/loaded_data_file.dart';
import 'package:abyss_relic/systems/config/config_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ConfigValidator accepts valid app config and table records', () {
    final validator = ConfigValidator();

    final errors = validator.validateFiles([
      _file(
        assetPath: 'assets/data/app_config.json',
        json: {
          'schemaVersion': 1,
          'id': 'abyss_relic',
          'displayName': '深渊遗装',
        },
      ),
      _file(
        assetPath: 'assets/data/classes.json',
        json: {
          'schemaVersion': 1,
          'classes': [
            {'id': 'exile', 'name': '流放者'},
            {'id': 'necrospeaker', 'name': '亡语者'},
          ],
        },
      ),
    ]);

    expect(errors, isEmpty);
  });

  test('ConfigValidator reports missing schemaVersion', () {
    final validator = ConfigValidator();

    final errors = validator.validateFiles([
      _file(
        assetPath: 'assets/data/classes.json',
        schemaVersion: 0,
        json: {
          'classes': [
            {'id': 'exile', 'name': '流放者'},
          ],
        },
      ),
    ]);

    expect(errors.single.code, ConfigValidationCode.missingSchemaVersion);
    expect(errors.single.assetPath, 'assets/data/classes.json');
    expect(errors.single.severity, ConfigValidationSeverity.error);
  });

  test('ConfigValidator reports missing required record fields', () {
    final validator = ConfigValidator();

    final errors = validator.validateFiles([
      _file(
        assetPath: 'assets/data/classes.json',
        json: {
          'schemaVersion': 1,
          'classes': [
            {'id': 'exile'},
            {'name': '亡语者'},
          ],
        },
      ),
    ]);

    expect(
      errors.map((error) => error.code),
      containsAll([
        ConfigValidationCode.missingRequiredField,
        ConfigValidationCode.missingRequiredField,
      ]),
    );
    expect(errors.any((error) => error.field == 'name'), isTrue);
    expect(errors.any((error) => error.field == 'id'), isTrue);
  });

  test('ConfigValidator reports duplicate ids inside a table', () {
    final validator = ConfigValidator();

    final errors = validator.validateFiles([
      _file(
        assetPath: 'assets/data/classes.json',
        json: {
          'schemaVersion': 1,
          'classes': [
            {'id': 'exile', 'name': '流放者'},
            {'id': 'exile', 'name': '重复流放者'},
          ],
        },
      ),
    ]);

    expect(errors.single.code, ConfigValidationCode.duplicateId);
    expect(errors.single.recordId, 'exile');
    expect(errors.single.tableName, 'classes');
  });

  test('ConfigValidator reports files with no records', () {
    final validator = ConfigValidator();

    final errors = validator.validateFiles([
      _file(
        assetPath: 'assets/data/empty.json',
        json: {'schemaVersion': 1},
      ),
    ]);

    expect(errors.single.code, ConfigValidationCode.missingRecords);
    expect(errors.single.assetPath, 'assets/data/empty.json');
  });
}

LoadedDataFile _file({
  required String assetPath,
  required Map<String, Object?> json,
  int schemaVersion = 1,
}) {
  return LoadedDataFile(
    meta: DataFileMeta(
      assetPath: assetPath,
      schemaVersion: schemaVersion,
      recordCount: 1,
      topLevelKeys: json.keys.toList(),
    ),
    json: json,
  );
}
