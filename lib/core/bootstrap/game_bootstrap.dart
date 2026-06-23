import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_config.dart';
import '../../systems/debug/debug_service.dart';

class GameBootstrap {
  const GameBootstrap({
    required this.config,
    required this.debugService,
  });

  final AppConfig config;
  final DebugService debugService;

  Map<String, Object?> toJson() {
    return {
      'config': config.toJson(),
      'debugService': debugService.toJson(),
    };
  }
}

final gameBootstrapProvider = Provider<GameBootstrap>((ref) {
  return const GameBootstrap(
    config: AppConfig(
      id: 'abyss_relic',
      displayName: '深渊遗装',
      version: '1.0.0',
      dataPath: 'assets/data/',
    ),
    debugService: DebugService(isEnabled: true),
  );
});
