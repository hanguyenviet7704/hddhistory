part of '../services.dart';

extension on Route<dynamic> {
  String get str => 'route(${settings.name}: ${settings.arguments})';
}

class BaseRouterObserver extends NavigatorObserver {
  final String observerName;
  final PageCubit _pageCubit;
  BaseRouterObserver(this.observerName, this._pageCubit);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log('didPush', route, previousRoute);
    onRouteChanged(route);
    onPushRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log('didPop', route, previousRoute);
    onRouteChanged(previousRoute);
    onPopRoute(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log('didRemove', route, previousRoute);
    onRouteChanged(previousRoute);
    onRemoveRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _log('didReplace', newRoute, oldRoute, isReplace: true);
    onRouteChanged(newRoute);
    onReplaceRoute(newRoute, oldRoute);
  }

  @override
  void didStartUserGesture(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log('didStartUserGesture', route, previousRoute);
  }

  @override
  void didStopUserGesture() {
    LogDev.one('$observerName didStopUserGesture');
  }

  void _log(String action, Route<dynamic>? route, Route<dynamic>? previousRoute, {bool isReplace = false}) {
    final previousText = isReplace ? 'oldRoute' : 'previousRoute';
    LogDev.one('$observerName $action: ${route?.str}, $previousText= ${previousRoute?.str}');
  }

  // Override this to handle route changes
  void onRouteChanged(Route<dynamic>? route) {
    _pageCubit.setCurrentRouteName(route?.settings.name ?? '');
  }

  void onPopRoute(Route<dynamic>? route) {
    _pageCubit.removeNavigationHistory(route?.settings.name ?? '');
  }

  void onClearRoute() {
    _pageCubit.clearNavigationHistory();
  }

  void onPushRoute(Route<dynamic> route) {
    _pageCubit.addNavigationHistory(route.settings.name ?? '');
    AppService.instance.appTrackingService.trackScreenView(route.settings.name ?? '');
  }

  void onReplaceRoute(Route<dynamic>? newRoute, Route<dynamic>? oldRoute) {
    _pageCubit.replaceNavigationHistory(newRoute?.settings.name ?? '', oldRoute?.settings.name ?? '');
    AppService.instance.appTrackingService.trackScreenView(newRoute?.settings.name ?? '');
  }

  void onRemoveRoute(Route<dynamic>? route) {
    _pageCubit.removeNavigationHistory(route?.settings.name ?? '');
  }
}

@LazySingleton(as: NavigatorObserver)
@Named(DIKey.appRouterObserver)
class AppRouterObserver extends BaseRouterObserver {
  AppRouterObserver(
    PageCubit pageCubit,
  ) : super('AppRouterObserver', pageCubit);
}

@LazySingleton(as: NavigatorObserver)
@Named(DIKey.homeRouterObserver)
class HomeRouterObserver extends BaseRouterObserver {
  HomeRouterObserver(
    PageCubit pageCubit,
  ) : super('HomeRouterObserver', pageCubit);
}

@LazySingleton(as: NavigatorObserver)
@Named(DIKey.courseRouterObserver)
class CourseRouterObserver extends BaseRouterObserver {
  CourseRouterObserver(
    PageCubit pageCubit,
  ) : super('CourseRouterObserver', pageCubit);
}

@LazySingleton(as: NavigatorObserver)
@Named(DIKey.settingRouterObserver)
class SettingRouterObserver extends BaseRouterObserver {
  SettingRouterObserver(
    PageCubit pageCubit,
  ) : super('SettingRouterObserver', pageCubit);
}
