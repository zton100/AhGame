import 'package:hive/hive.dart';

import 'save_store.dart';

class HiveSaveStore implements SaveStore {
  const HiveSaveStore({
    required Box<dynamic> box,
    this.saveSlotKey = primarySaveSlotKey,
  }) : _box = box;

  static const String primarySaveSlotKey = 'primary_save';
  static const String primaryBackupSlotKey = 'primary_save_backup';

  final Box<dynamic> _box;
  final String saveSlotKey;

  @override
  Future<Map<String, Object?>?> read() async {
    final value = _box.get(saveSlotKey);
    if (value == null) {
      return null;
    }

    final normalized = _normalizeJsonValue(value);
    if (normalized is Map<String, Object?>) {
      return normalized;
    }

    throw FormatException(
        'Save slot $saveSlotKey does not contain a JSON object.');
  }

  @override
  Future<void> write(Map<String, Object?> json) {
    return _box.put(saveSlotKey, _normalizeJsonValue(json));
  }

  @override
  Future<void> delete() {
    return _box.delete(saveSlotKey);
  }
}

Object? _normalizeJsonValue(Object? value) {
  if (value is Map) {
    return {
      for (final entry in value.entries)
        entry.key.toString(): _normalizeJsonValue(entry.value),
    };
  }

  if (value is Iterable) {
    return value.map(_normalizeJsonValue).toList(growable: false);
  }

  return value;
}
