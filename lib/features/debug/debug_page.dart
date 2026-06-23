import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/bootstrap/game_bootstrap.dart';
import '../../core/routing/app_route.dart';
import '../../core/theme/quality_theme.dart';
import '../../systems/config/game_database_service.dart';
import '../../systems/navigation/navigation_service.dart';

class DebugPage extends ConsumerWidget {
  const DebugPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(gameBootstrapProvider);
    final databaseLoad = ref.watch(gameDatabaseLoadProvider);
    final tabs = const NavigationService().mainTabs;

    return Scaffold(
      appBar: AppBar(title: const Text('Debug')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DebugSection(
            title: 'Bootstrap',
            rows: {
              'app_id': bootstrap.config.id,
              'display_name': bootstrap.config.displayName,
              'version': bootstrap.config.version,
              'data_path': bootstrap.config.dataPath,
              'debug_enabled': bootstrap.debugService.isEnabled.toString(),
            },
          ),
          const SizedBox(height: 12),
          databaseLoad.when(
            data: (result) {
              final issueRows = {
                for (final issue in result.issues.take(5))
                  '${issue.source.name}:${issue.code}':
                      '${issue.assetPath} - ${issue.message}',
              };

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DebugSection(
                    title: 'Config Database',
                    rows: {
                      'files': result.summary.fileCount.toString(),
                      'records': result.summary.recordCount.toString(),
                      'errors': result.summary.errorCount.toString(),
                      'tables': result.database.tableNames.join(', '),
                    },
                  ),
                  if (issueRows.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _DebugSection(
                      title: 'Config Issues',
                      rows: issueRows,
                    ),
                  ],
                ],
              );
            },
            error: (error, _) {
              return _DebugSection(
                title: 'Config Database',
                rows: {'error': error.toString()},
              );
            },
            loading: () {
              return const _DebugSection(
                title: 'Config Database',
                rows: {'status': 'Loading config database...'},
              );
            },
          ),
          const SizedBox(height: 12),
          _DebugSection(
            title: 'Navigation',
            rows: {
              for (final AppRoute route in tabs) route.id: route.label,
            },
          ),
          const SizedBox(height: 12),
          _DebugSection(
            title: 'Quality Tokens',
            rows: {
              for (final quality in EquipmentQuality.values)
                quality.id: quality.label,
            },
          ),
        ],
      ),
    );
  }
}

class _DebugSection extends StatelessWidget {
  const _DebugSection({required this.title, required this.rows});

  final String title;
  final Map<String, String> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final row in rows.entries)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        row.key,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Expanded(child: Text(row.value)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
