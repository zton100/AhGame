abstract class SaveStore {
  Future<Map<String, Object?>?> read();

  Future<void> write(Map<String, Object?> json);

  Future<void> delete();
}
