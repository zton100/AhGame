import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/bootstrap/game_bootstrap.dart';
import 'core/save/player_save_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/main_shell.dart';
import 'systems/save/backup_service.dart';
import 'systems/save/hive_save_store.dart';
import 'systems/save/save_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final saveBox = await Hive.openBox<dynamic>('saves');

  runApp(
    ProviderScope(
      overrides: [
        saveServiceProvider.overrideWithValue(
          SaveService(
            store: HiveSaveStore(box: saveBox),
            backupService: BackupService(
              backupStore: HiveSaveStore(
                box: saveBox,
                saveSlotKey: HiveSaveStore.primaryBackupSlotKey,
              ),
            ),
          ),
        ),
      ],
      child: const AbyssRelicApp(),
    ),
  );
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
