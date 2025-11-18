part of '../routes.dart';

//* Shell routes - Setting
class SettingShellBranchData extends StatefulShellBranchData {
  const SettingShellBranchData();
  // static final GlobalKey<NavigatorState> $navigatorKey = AppConfig.rootNaviKey;
  static final List<NavigatorObserver> $observers = [AppConfig.instance.settingRouterObserver];
}

//? Setting Route
class SettingRoute extends BaseTransitionRouteData with $SettingRoute {
  const SettingRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => const SettingPage();
}
