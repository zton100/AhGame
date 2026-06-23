import '../../models/save_data.dart';
import 'save_service.dart';

class AutoSaveService {
  AutoSaveService({
    required SaveService saveService,
    DateTime Function()? now,
    this.minimumInterval = const Duration(seconds: 10),
  })  : _saveService = saveService,
        _now = now ?? DateTime.now;

  final SaveService _saveService;
  final DateTime Function() _now;
  final Duration minimumInterval;

  DateTime? _lastAutoSaveAt;
  String? _lastError;

  DateTime? get lastAutoSaveAt => _lastAutoSaveAt;
  String? get lastError => _lastError;

  Future<AutoSaveResult> saveAfterAction(
    SaveData saveData, {
    String reason = 'action',
    bool force = false,
  }) {
    return _save(saveData, reason: reason, force: force);
  }

  Future<AutoSaveResult> recordAppExit(SaveData saveData) {
    final timestamp = _now().toUtc();
    return _save(
      saveData.copyWith(lastExitAt: timestamp),
      reason: 'app_exit',
      force: true,
    );
  }

  Future<AutoSaveResult> _save(
    SaveData saveData, {
    required String reason,
    required bool force,
  }) async {
    final timestamp = _now().toUtc();
    if (!force && _lastAutoSaveAt != null) {
      final elapsed = timestamp.difference(_lastAutoSaveAt!);
      if (elapsed < minimumInterval) {
        return AutoSaveResult.skipped(
          reason: reason,
          skippedAt: timestamp,
          nextAllowedAt: _lastAutoSaveAt!.add(minimumInterval),
        );
      }
    }

    try {
      await _saveService.save(saveData);
      _lastAutoSaveAt = timestamp;
      _lastError = null;
      return AutoSaveResult.saved(reason: reason, savedAt: timestamp);
    } on Object catch (error) {
      _lastError = error.toString();
      return AutoSaveResult.failed(
        reason: reason,
        attemptedAt: timestamp,
        error: _lastError!,
      );
    }
  }
}

class AutoSaveResult {
  const AutoSaveResult._({
    required this.reason,
    required this.status,
    required this.timestamp,
    this.nextAllowedAt,
    this.error,
  });

  factory AutoSaveResult.saved({
    required String reason,
    required DateTime savedAt,
  }) {
    return AutoSaveResult._(
      reason: reason,
      status: AutoSaveStatus.saved,
      timestamp: savedAt,
    );
  }

  factory AutoSaveResult.skipped({
    required String reason,
    required DateTime skippedAt,
    required DateTime nextAllowedAt,
  }) {
    return AutoSaveResult._(
      reason: reason,
      status: AutoSaveStatus.skipped,
      timestamp: skippedAt,
      nextAllowedAt: nextAllowedAt,
    );
  }

  factory AutoSaveResult.failed({
    required String reason,
    required DateTime attemptedAt,
    required String error,
  }) {
    return AutoSaveResult._(
      reason: reason,
      status: AutoSaveStatus.failed,
      timestamp: attemptedAt,
      error: error,
    );
  }

  final String reason;
  final AutoSaveStatus status;
  final DateTime timestamp;
  final DateTime? nextAllowedAt;
  final String? error;
}

enum AutoSaveStatus { saved, skipped, failed }
