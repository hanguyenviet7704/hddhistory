part of '../services.dart';

extension on Route<dynamic> {
  String get str => 'route(${settings.name}: ${settings.arguments})';
}

/// [NavigatorObserver.didRemove] fires when a route is pruned from ANYWHERE
/// in the stack, not only from the top — e.g. go_router pushes a sibling
/// route (KeypointComplete) on top of the current one (Lesson, both direct
/// children of course-roadmap) and then removes the now-unreachable Lesson
/// route. Naively writing that removal's `previousRoute` as the new current
/// route clobbers [PageCubit.currentRouteName] with a stale — often PRIMARY —
/// name even though the actually-visible top route (KeypointComplete) never
/// changed, un-hiding the shell's floating nav over its CTA. Only trust a
/// didRemove signal when the removed route was the one actually being
/// tracked as current (a real top-of-stack removal, e.g. Navigator.removeRoute).
bool shouldUpdateCurrentRouteOnRemove({
  required String removedRouteName,
  required String trackedCurrentRouteName,
}) => removedRouteName.isNotEmpty && removedRouteName == trackedCurrentRouteName;

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
    if (shouldUpdateCurrentRouteOnRemove(
      removedRouteName: route.settings.name ?? '',
      trackedCurrentRouteName: _pageCubit.state.currentRouteName,
    )) {
      onRouteChanged(previousRoute);
    }
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

  @override
  void onPopRoute(Route<dynamic>? route) {
    super.onPopRoute(route);
    if (route?.settings.name != RouteNamed.course) return;
    final courseCubit = AppDI.injector.get<CourseCubit>();
    courseCubit.setAllCourseSource('unknown');
  }
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
@Named(DIKey.exploreRouterObserver)
class ExploreRouterObserver extends BaseRouterObserver {
  ExploreRouterObserver(
    PageCubit pageCubit,
  ) : super('ExploreRouterObserver', pageCubit);

  @override
  void onPopRoute(Route<dynamic>? route) {
    super.onPopRoute(route);
    // CoursePage (/course) lives in the Explore branch, so its pop is observed
    // here. Reset the analytics source when leaving the explore grid.
    if (route?.settings.name != RouteNamed.course) return;
    final courseCubit = AppDI.injector.get<CourseCubit>();
    courseCubit.setAllCourseSource('unknown');
  }
}

@LazySingleton(as: NavigatorObserver)
@Named(DIKey.settingRouterObserver)
class SettingRouterObserver extends BaseRouterObserver {
  SettingRouterObserver(
    PageCubit pageCubit,
  ) : super('SettingRouterObserver', pageCubit);
}
