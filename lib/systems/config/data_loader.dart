import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../models/config_load_error.dart';
import '../../models/data_file_meta.dart';
import '../../models/loaded_data_file.dart';
import 'config_load_result.dart';

class DataLoader {
  const DataLoader({AssetBundle? bundle}) : _bundle = bundle;

  final AssetBundle? _bundle;

  AssetBundle get _resolvedBundle => _bundle ?? rootBundle;

  Future<ConfigLoadResult> loadJsonFile(String assetPath) async {
    try {
      final raw = await _resolvedBundle.loadString(assetPath);
      final decoded = jsonDecode(raw);

      if (decoded is! Map<String, Object?>) {
        return ConfigLoadResult.failure(
          ConfigLoadError(
            assetPath: assetPath,
            type: ConfigLoadErrorType.invalidRoot,
            message: 'Config root must be a JSON object.',
          ),
        );
      }

      final schemaVersion = decoded['schemaVersion'];
      if (schemaVersion is! int) {
        return ConfigLoadResult.failure(
          ConfigLoadError(
            assetPath: assetPath,
            type: ConfigLoadErrorType.missingSchemaVersion,
            message: 'Config must include an integer schemaVersion.',
          ),
        );
      }

      return ConfigLoadResult.success(
        LoadedDataFile(
          meta: DataFileMeta(
            assetPath: assetPath,
            schemaVersion: schemaVersion,
            recordCount: _countRecords(decoded),
            topLevelKeys: decoded.keys.toList()..sort(),
          ),
          json: decoded,
        ),
      );
    } on FormatException catch (error) {
      return ConfigLoadResult.failure(
        ConfigLoadError(
          assetPath: assetPath,
          type: ConfigLoadErrorType.invalidJson,
          message: error.message,
        ),
      );
    } on FlutterError catch (error) {
      return ConfigLoadResult.failure(
        ConfigLoadError(
          assetPath: assetPath,
          type: ConfigLoadErrorType.assetNotFound,
          message: error.message,
        ),
      );
    } on Object catch (error) {
      return ConfigLoadResult.failure(
        ConfigLoadError(
          assetPath: assetPath,
          type: ConfigLoadErrorType.unexpected,
          message: error.toString(),
        ),
      );
    }
  }

  Future<List<ConfigLoadResult>> loadJsonFiles(List<String> assetPaths) {
    return Future.wait(assetPaths.map(loadJsonFile));
  }

  Future<List<ConfigLoadResult>> loadDataDirectory({
    String prefix = 'assets/data/',
  }) async {
    final manifest = await AssetManifest.loadFromAssetBundle(_resolvedBundle);
    final dataAssets = manifest.listAssets().where((assetPath) {
      return assetPath.startsWith(prefix) && assetPath.endsWith('.json');
    }).toList()
      ..sort();

    return loadJsonFiles(dataAssets);
  }

  int _countRecords(Map<String, Object?> json) {
    for (final value in json.values) {
      if (value is List<Object?>) {
        return value.length;
      }
    }
    return 1;
  }
}
