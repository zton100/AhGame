import '../../models/data_file_meta.dart';
import '../../models/loaded_data_file.dart';

class GameDatabase {
  GameDatabase._({
    required Map<String, LoadedDataFile> files,
    required Map<String, Map<String, Map<String, Object?>>> tables,
  })  : _files = Map<String, LoadedDataFile>.unmodifiable(files),
        _tables = Map<String, Map<String, Map<String, Object?>>>.unmodifiable({
          for (final entry in tables.entries)
            entry.key: Map<String, Map<String, Object?>>.unmodifiable(
              entry.value,
            ),
        });

  factory GameDatabase.fromFiles(Iterable<LoadedDataFile> files) {
    final filesByPath = <String, LoadedDataFile>{};
    final tables = <String, Map<String, Map<String, Object?>>>{};

    for (final file in files) {
      filesByPath[file.meta.assetPath] = file;
      final tableName = _tableNameForFile(file.meta.assetPath);
      final json = file.json;

      MapEntry<String, Object?>? listEntry;
      for (final entry in json.entries) {
        if (entry.value is List<Object?>) {
          listEntry = entry;
          break;
        }
      }
      if (listEntry != null) {
        final records = listEntry.value as List<Object?>;
        for (final record in records.whereType<Map<String, Object?>>()) {
          _addRecord(tables, listEntry.key, record);
        }
        continue;
      }

      if (json['id'] is String) {
        _addRecord(tables, tableName, json);
      }
    }

    return GameDatabase._(files: filesByPath, tables: tables);
  }

  final Map<String, LoadedDataFile> _files;
  final Map<String, Map<String, Map<String, Object?>>> _tables;

  int get fileCount => _files.length;

  int get recordCount {
    return _tables.values.fold<int>(0, (sum, table) => sum + table.length);
  }

  List<String> get tableNames => _tables.keys.toList()..sort();

  DataFileMeta? findFile(String assetPath) => _files[assetPath]?.meta;

  DataFileMeta requireFile(String assetPath) {
    final file = findFile(assetPath);
    if (file == null) {
      throw StateError('Config file not found: $assetPath');
    }
    return file;
  }

  Map<String, Object?>? findRecord(String tableName, String id) {
    return _tables[tableName]?[id];
  }

  Map<String, Map<String, Object?>> recordsForTable(String tableName) {
    return _tables[tableName] ?? const {};
  }

  Map<String, Object?> toJson() {
    return {
      'files': _files.map((key, value) => MapEntry(key, value.meta.toJson())),
      'tables': _tables,
    };
  }

  static void _addRecord(
    Map<String, Map<String, Map<String, Object?>>> tables,
    String tableName,
    Map<String, Object?> record,
  ) {
    final id = record['id'];
    if (id is! String) {
      return;
    }

    tables.putIfAbsent(tableName, () => <String, Map<String, Object?>>{});
    tables[tableName]![id] = Map.unmodifiable(record);
  }

  static String _tableNameForFile(String assetPath) {
    final fileName = assetPath.split('/').last;
    return fileName.endsWith('.json')
        ? fileName.substring(0, fileName.length - '.json'.length)
        : fileName;
  }
}
