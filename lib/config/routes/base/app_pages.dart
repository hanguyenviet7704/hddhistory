part of '../routes.dart';

mixin AppPages {
  static final GoRouter routes = GoRouter(
    navigatorKey: AppConfig.instance.rootNaviKey,
    // initialLocation: RoutePath.splash,
    initialLocation: RoutePath.paywall,
    debugLogDiagnostics: true,
    observers: [AppConfig.instance.appRouterObserver],
    routes: $appRoutes,
    errorPageBuilder: AppService.instance.errorPageBuilder,
  );
}
