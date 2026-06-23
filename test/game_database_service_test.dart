import 'dart:convert';

import 'package:abyss_relic/models/config_load_error.dart';
import 'package:abyss_relic/systems/config/data_loader.dart';
import 'package:abyss_relic/systems/config/game_database_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('GameDatabaseService builds a database from loaded config files',
      () async {
    final service = GameDatabaseService(
      dataLoader: DataLoader(
        bundle: _FakeAssetBundle({
          'assets/data/app_config.json': '''
            {
              "schemaVersion": 1,
              "id": "abyss_relic",
              "displayName": "深渊遗装"
            }
          ''',
          'assets/data/classes.json': '''
            {
              "schemaVersion": 1,
              "classes": [
                {"id": "exile", "name": "流放者"},
                {"id": "necrospeaker", "name": "亡语者"}
              ]
            }
          ''',
        }),
      ),
    );

    final result = await service.loadFromAssets([
      'assets/data/app_config.json',
      'assets/data/classes.json',
    ]);

    expect(result.hasErrors, isFalse);
    expect(result.summary.fileCount, 2);
    expect(result.summary.recordCount, 3);
    expect(
        result.database.requireFile('assets/data/classes.json').recordCount, 2);
    expect(result.database.findRecord('classes', 'exile')?['name'], '流放者');
    expect(result.database.findRecord('classes', 'missing'), isNull);
  });

  test('GameDatabaseService keeps load errors visible', () async {
    final service = GameDatabaseService(
      dataLoader: DataLoader(
        bundle: _FakeAssetBundle({
          'assets/data/app_config.json': '''
            {
              "schemaVersion": 1,
              "id": "abyss_relic",
              "displayName": "深渊遗装"
            }
          ''',
          'assets/data/broken.json': '{not json',
        }),
      ),
    );

    final result = await service.loadFromAssets([
      'assets/data/app_config.json',
      'assets/data/broken.json',
    ]);

    expect(result.hasErrors, isTrue);
    expect(result.summary.fileCount, 1);
    expect(result.summary.errorCount, 1);
    expect(result.errors.single.type, ConfigLoadErrorType.invalidJson);
    expect(result.issues.single.source.name, 'load');
    expect(result.database.findRecord('app_config', 'abyss_relic'), isNotNull);
  });

  test('GameDatabaseService includes validation errors in the summary',
      () async {
    final service = GameDatabaseService(
      dataLoader: DataLoader(
        bundle: _FakeAssetBundle({
          'assets/data/classes.json': '''
            {
              "schemaVersion": 1,
              "classes": [
                {"id": "exile"}
              ]
            }
          ''',
        }),
      ),
    );

    final result = await service.loadFromAssets([
      'assets/data/classes.json',
    ]);

    expect(result.hasErrors, isTrue);
    expect(result.summary.fileCount, 1);
    expect(result.summary.errorCount, 1);
    expect(result.validationErrors.single.field, 'name');
    expect(result.issues.single.source.name, 'validation');
  });
}

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this.assets);

  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin.json') {
      return _byteDataForJson({
        for (final assetPath in assets.keys) assetPath: <String>[],
      });
    }

    final value = assets[key];
    if (value == null) {
      throw FlutterError('Unable to load asset: $key');
    }

    return ByteData.view(Uint8List.fromList(utf8.encode(value)).buffer);
  }

  ByteData _byteDataForJson(Object value) {
    return ByteData.view(
      Uint8List.fromList(utf8.encode(jsonEncode(value))).buffer,
    );
  }
}
