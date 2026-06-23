import 'dart:convert';

import 'package:abyss_relic/models/config_load_error.dart';
import 'package:abyss_relic/systems/config/config_loader.dart';
import 'package:abyss_relic/systems/config/data_loader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ConfigLoader reads registered asset data', () async {
    const loader = ConfigLoader();

    final raw = await loader.loadRaw('assets/data/app_config.json');

    expect(raw, contains('"id": "abyss_relic"'));
    expect(raw, contains('"schemaVersion": 1'));
  });

  test('DataLoader parses JSON config metadata', () async {
    final loader = DataLoader(
      bundle: _FakeAssetBundle({
        'assets/data/classes.json': '''
          {
            "schemaVersion": 1,
            "classes": [
              {"id": "exile"},
              {"id": "necrospeaker"}
            ]
          }
        ''',
      }),
    );

    final result = await loader.loadJsonFile('assets/data/classes.json');

    expect(result.isSuccess, isTrue);
    expect(result.requireData.meta.assetPath, 'assets/data/classes.json');
    expect(result.requireData.meta.schemaVersion, 1);
    expect(result.requireData.meta.recordCount, 2);
    expect(result.requireData.meta.topLevelKeys, ['classes', 'schemaVersion']);
  });

  test('DataLoader reports missing assets', () async {
    final loader = DataLoader(bundle: _FakeAssetBundle({}));

    final result = await loader.loadJsonFile('assets/data/missing.json');

    expect(result.isFailure, isTrue);
    expect(
      result.requireError.type,
      ConfigLoadErrorType.assetNotFound,
    );
  });

  test('DataLoader reports invalid JSON', () async {
    final loader = DataLoader(
      bundle: _FakeAssetBundle({
        'assets/data/broken.json': '{not json',
      }),
    );

    final result = await loader.loadJsonFile('assets/data/broken.json');

    expect(result.isFailure, isTrue);
    expect(result.requireError.type, ConfigLoadErrorType.invalidJson);
  });

  test('DataLoader requires object root', () async {
    final loader = DataLoader(
      bundle: _FakeAssetBundle({
        'assets/data/list.json': '[1, 2, 3]',
      }),
    );

    final result = await loader.loadJsonFile('assets/data/list.json');

    expect(result.isFailure, isTrue);
    expect(result.requireError.type, ConfigLoadErrorType.invalidRoot);
  });

  test('DataLoader requires integer schemaVersion', () async {
    final loader = DataLoader(
      bundle: _FakeAssetBundle({
        'assets/data/no_schema.json': '{"items": []}',
      }),
    );

    final result = await loader.loadJsonFile('assets/data/no_schema.json');

    expect(result.isFailure, isTrue);
    expect(
      result.requireError.type,
      ConfigLoadErrorType.missingSchemaVersion,
    );
  });
}

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this.assets);

  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) async {
    final value = assets[key];
    if (value == null) {
      throw FlutterError('Unable to load asset: $key');
    }

    final bytes = utf8.encode(value);
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }
}
