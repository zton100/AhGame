import 'package:flutter/widgets.dart';

import '../../models/save_data.dart';
import 'auto_save_service.dart';

class AppLifecycleAutoSaveObserver with WidgetsBindingObserver {
  AppLifecycleAutoSaveObserver({
    required AutoSaveService autoSaveService,
    required Future<SaveData> Function() loadCurrentSave,
  })  : _autoSaveService = autoSaveService,
        _loadCurrentSave = loadCurrentSave;

  final AutoSaveService _autoSaveService;
  final Future<SaveData> Function() _loadCurrentSave;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    handleLifecycleState(state);
  }

  Future<AutoSaveResult?> handleLifecycleState(AppLifecycleState state) async {
    if (!_shouldSaveFor(state)) {
      return null;
    }

    final saveData = await _loadCurrentSave();
    return _autoSaveService.recordAppExit(saveData);
  }

  bool _shouldSaveFor(AppLifecycleState state) {
    return state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden;
  }
}
