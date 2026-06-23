import 'data_file_meta.dart';

class LoadedDataFile {
  const LoadedDataFile({
    required this.meta,
    required this.json,
  });

  final DataFileMeta meta;
  final Map<String, Object?> json;

  Map<String, Object?> toJson() {
    return {
      'meta': meta.toJson(),
      'json': json,
    };
  }
}
