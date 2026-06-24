import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/routing/app_route.dart';
import '../../core/theme/app_theme.dart';
import '../../systems/navigation/navigation_service.dart';
import '../battle/battle_page.dart';
import '../character/character_page.dart';
import '../debug/debug_page.dart';
import '../equipment/equipment_page.dart';
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
        return const BattlePage();
      case AppRoute.equipment:
        return const EquipmentPage();
      case AppRoute.build:
        return FeaturePlaceholderPage(
          title: route.label,
          routeId: route.id,
          summary: '构筑标签、匹配评分、关键缺口和推荐词缀会在这里接入。',
        );
      case AppRoute.abyss:
        return FeaturePlaceholderPage(
          title: route.label,
          routeId: route.id,
          summary: '领域、难度、层数词缀和首通奖励会在这里接入。',
        );
      case AppRoute.character:
        return const CharacterPage();
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
