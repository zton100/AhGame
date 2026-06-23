import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/routing/app_route.dart';
import '../../core/theme/app_theme.dart';
import '../../systems/navigation/navigation_service.dart';
import '../debug/debug_page.dart';
import '../placeholder/feature_placeholder_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _navigationService = const NavigationService();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = _navigationService.mainTabs;
    final selectedRoute = tabs[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('深渊遗装'),
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: 'Open debug panel',
              icon: const Icon(Icons.bug_report_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DebugPage(),
                  ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: DecoratedBox(
          decoration: const BoxDecoration(color: AppTheme.background),
          child: IndexedStack(
            index: _selectedIndex,
            children: tabs.map(_buildPageForRoute).toList(),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: tabs.map((route) {
          return NavigationDestination(
            icon: Icon(_iconForRoute(route)),
            label: route.label,
            tooltip: route.label,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPageForRoute(AppRoute route) {
    switch (route) {
      case AppRoute.battle:
        return const FeaturePlaceholderPage(
          title: '战斗',
          routeId: 'battle',
          summary: '自动战斗、掉落提示和战斗日志会在这里接入。',
        );
      case AppRoute.equipment:
        return const FeaturePlaceholderPage(
          title: '装备',
          routeId: 'equipment',
          summary: '背包、穿戴、锁定、分解和装备详情会在这里接入。',
        );
      case AppRoute.build:
        return const FeaturePlaceholderPage(
          title: 'BD',
          routeId: 'build',
          summary: '构筑标签、匹配评分、关键缺口和推荐词缀会在这里接入。',
        );
      case AppRoute.abyss:
        return const FeaturePlaceholderPage(
          title: '深渊',
          routeId: 'abyss',
          summary: '领域、难度、层数词缀和首通奖励会在这里接入。',
        );
      case AppRoute.character:
        return const FeaturePlaceholderPage(
          title: '角色',
          routeId: 'character',
          summary: '职业、等级、属性拆解和系统解锁会在这里接入。',
        );
      case AppRoute.debug:
        return const DebugPage();
    }
  }

  IconData _iconForRoute(AppRoute route) {
    switch (route) {
      case AppRoute.battle:
        return Icons.flash_on_outlined;
      case AppRoute.equipment:
        return Icons.inventory_2_outlined;
      case AppRoute.build:
        return Icons.hub_outlined;
      case AppRoute.abyss:
        return Icons.blur_circular_outlined;
      case AppRoute.character:
        return Icons.person_outline;
      case AppRoute.debug:
        return Icons.bug_report_outlined;
    }
  }
}
