import '../../core/routing/app_route.dart';

class NavigationService {
  const NavigationService();

  List<AppRoute> get mainTabs {
    return const [
      AppRoute.battle,
      AppRoute.equipment,
      AppRoute.build,
      AppRoute.abyss,
      AppRoute.character,
    ];
  }
}
