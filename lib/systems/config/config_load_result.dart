import '../../models/config_load_error.dart';
import '../../models/loaded_data_file.dart';

class ConfigLoadResult {
  const ConfigLoadResult._({this.data, this.error});

  factory ConfigLoadResult.success(LoadedDataFile data) {
    return ConfigLoadResult._(data: data);
  }

  factory ConfigLoadResult.failure(ConfigLoadError error) {
    return ConfigLoadResult._(error: error);
  }

  final LoadedDataFile? data;
  final ConfigLoadError? error;

  bool get isSuccess => data != null;
  bool get isFailure => error != null;

  LoadedDataFile get requireData {
    final value = data;
    if (value == null) {
      throw StateError('Config load result has no data.');
    }
    return value;
  }

  ConfigLoadError get requireError {
    final value = error;
    if (value == null) {
      throw StateError('Config load result has no error.');
    }
    return value;
  }
}
