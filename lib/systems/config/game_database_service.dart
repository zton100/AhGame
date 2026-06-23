import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/config_load_error.dart';
import '../../models/config_validation_error.dart';
import '../../models/loaded_data_file.dart';
import 'config_validator.dart';
import 'data_loader.dart';
import 'game_database.dart';
import 'game_database_load_result.dart';
import 'reference_resolver.dart';

class GameDatabaseService {
  const GameDatabaseService({
    required DataLoader dataLoader,
    ConfigValidator validator = const ConfigValidator(),
    ReferenceResolver referenceResolver = const ReferenceResolver(),
  })  : _dataLoader = dataLoader,
        _validator = validator,
        _referenceResolver = referenceResolver;

  final DataLoader _dataLoader;
  final ConfigValidator _validator;
  final ReferenceResolver _referenceResolver;

  Future<GameDatabaseLoadResult> loadFromAssets(List<String> assetPaths) async {
    final results = await _dataLoader.loadJsonFiles(assetPaths);
    return _buildResult(
      loadedFiles: [
        for (final result in results)
          if (result.data != null) result.requireData,
      ],
      errors: [
        for (final result in results)
          if (result.error != null) result.requireError,
      ],
    );
  }

  Future<GameDatabaseLoadResult> loadDataDirectory() async {
    final results = await _dataLoader.loadDataDirectory();
    return _buildResult(
      loadedFiles: [
        for (final result in results)
          if (result.data != null) result.requireData,
      ],
      errors: [
        for (final result in results)
          if (result.error != null) result.requireError,
      ],
    );
  }

  GameDatabaseLoadResult _buildResult({
    required List<LoadedDataFile> loadedFiles,
    required List<ConfigLoadError> errors,
  }) {
    final database = GameDatabase.fromFiles(loadedFiles);
    final validationErrors = [
      ..._validator.validateFiles(loadedFiles),
      ..._referenceResolver.check(database),
    ];

    return GameDatabaseLoadResult(
      database: database,
      errors: List.unmodifiable(errors),
      validationErrors: List<ConfigValidationError>.unmodifiable(
        validationErrors,
      ),
    );
  }
}

final gameDatabaseLoadProvider = FutureProvider<GameDatabaseLoadResult>((ref) {
  return const GameDatabaseService(dataLoader: DataLoader())
      .loadDataDirectory();
});
