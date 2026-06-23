import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/bootstrap/game_bootstrap.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/main_shell.dart';

void main() {
  runApp(const ProviderScope(child: AbyssRelicApp()));
}

class AbyssRelicApp extends ConsumerWidget {
  const AbyssRelicApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(gameBootstrapProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: bootstrap.config.displayName,
      theme: AppTheme.dark(),
      home: const MainShell(),
    );
  }
}
