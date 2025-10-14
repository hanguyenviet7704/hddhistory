part of 'routes.dart';

mixin AppPages {
  static final GoRouter routes = GoRouter(
    navigatorKey: AppConfig.instance.rootNaviKey,
    initialLocation: RoutePath.splash,
    debugLogDiagnostics: true,
    observers: [AppConfig.instance.appRouterObserver],
    routes: $appRoutes,
    errorPageBuilder: AppService.instance.errorPageBuilder,
  );
}
