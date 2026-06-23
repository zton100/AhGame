import 'save_data.dart';

class MigrationResult {
  const MigrationResult({
    required this.success,
    required this.saveData,
    this.warnings = const [],
    this.error,
  });

  final bool success;
  final SaveData saveData;
  final List<String> warnings;
  final String? error;
}
