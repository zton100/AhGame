import 'save_store.dart';

class InMemorySaveStore implements SaveStore {
  Map<String, Object?>? _json;

  @override
  Future<Map<String, Object?>?> read() async {
    final json = _json;
    return json == null ? null : Map<String, Object?>.from(json);
  }

  @override
  Future<void> write(Map<String, Object?> json) async {
    _json = Map<String, Object?>.from(json);
  }

  @override
  Future<void> delete() async {
    _json = null;
  }
}
