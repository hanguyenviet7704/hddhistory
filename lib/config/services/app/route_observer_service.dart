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
///
/// `didPop` reuses this for the NAMED case, where the same reasoning holds. Its
/// unnamed case cannot use it — an overlay has no name to compare — and is
/// handled by [BaseRouterObserver._pagesUnderOverlays] instead. The
/// "OnRemove" name is kept even though two callers share it: the test file pins
/// it.
bool shouldUpdateCurrentRouteOnRemove({
  required String removedRouteName,
  required String trackedCurrentRouteName,
}) => removedRouteName.isNotEmpty && removedRouteName == trackedCurrentRouteName;

class BaseRouterObserver extends NavigatorObserver {
  final String observerName;
  final PageCubit _pageCubit;
  BaseRouterObserver(this.observerName, this._pageCubit);

  /// Page names that unnamed overlays are currently covering, innermost last.
  ///
  /// An unnamed route (dialog, bottom sheet, the saved-card detail overlay)
  /// blanks the pointer on push, and that blanking is exactly what hides the
  /// floating nav underneath it — 35-odd surfaces rely on it. But it also leaves
  /// the pop with nothing to restore except `previousRoute`, and for an overlay
  /// pushed on the ROOT navigator that is the SHELL, whose name is primary: the
  /// nav came back over whatever non-primary page the reader was really on
  /// ("lúc thì có nav lúc không" on Saved cards, 2026-08-18).
  ///
  /// A stack, not one field, so nested overlays each restore their own caller.
  ///
  /// STATIC, not per-instance, and that is the whole fix for "bấm ⋯ rồi thoát ra
  /// là mất nav". There is one observer PER NAVIGATOR (root + one per shell
  /// branch), but an overlay's push and its pop are not guaranteed to be seen by
  /// the SAME one: the ⋯ sheet is pushed on the shell navigator (it passes no
  /// `useRootNavigator`), while a close that goes through go_router's `pop`
  /// reaches the ROOT navigator. The root observer then had an empty stack, so
  /// the `isNotEmpty` guard below simply did nothing — and the pointer stayed on
  /// the blank an overlay push writes, which is exactly what hides the nav. The
  /// nav was not restored because nobody was left holding the name.
  ///
  /// Overlays nest in TIME, not per navigator, so one shared stack matches what
  /// is actually on screen. Sharing it also means whichever observer sees the
  /// pop can restore what whichever observer saw the push.
  static final List<String> _pagesUnderOverlays = [];

  /// Clears the shared overlay stack.
  ///
  /// Exists because the stack is `static`: no test constructs a real
  /// [BaseRouterObserver] today, but the first one that does would inherit
  /// whatever a previous test left behind, and debugging that from a failing
  /// expectation is miserable.
  @visibleForTesting
  static void resetOverlayStackForTest() => _pagesUnderOverlays.clear();

  /// The page name to restore when this overlay closes.
  ///
  /// Prefers the tracked pointer: for an overlay on the ROOT navigator
  /// `previousRoute` is the SHELL, whose name is primary, and restoring that
  /// showed the nav over a non-primary page (the bug this stack was built for).
  /// Falls back to the navigator's own stack only when the pointer is blank —
  /// nested overlays, where the outer one already blanked it. A name that shows
  /// the nav on the wrong page is a smaller wrong than no nav at all.
  String _pageUnderOverlay(Route<dynamic>? previousRoute) {
    final tracked = _pageCubit.state.currentRouteName;
    if (tracked.isNotEmpty) return tracked;

    return previousRoute?.settings.name ?? '';
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log('didPush', route, previousRoute);
    if ((route.settings.name ?? '').isEmpty) {
      _pagesUnderOverlays.add(_pageUnderOverlay(previousRoute));
    }
    onRouteChanged(route);
    onPushRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log('didPop', route, previousRoute);
    final poppedName = route.settings.name ?? '';
    if (poppedName.isEmpty) {
      // An overlay closing: hand the pointer back to the page it was covering,
      // NOT to `previousRoute`. See [_pagesUnderOverlays].
      final under = _pagesUnderOverlays.isNotEmpty ? _pagesUnderOverlays.removeLast() : '';
      // Never hand back a BLANK. A blank pointer is what hides the floating nav,
      // so restoring one on close leaves the uncovered page looking like it is
      // still covered — nav gone, nothing in the logs. When the stack has nothing
      // usable, fall back to the route physically underneath.
      final restored = under.isNotEmpty ? under : (previousRoute?.settings.name ?? '');
      if (restored.isNotEmpty) _pageCubit.setCurrentRouteName(restored);
    } else if (shouldUpdateCurrentRouteOnRemove(
      removedRouteName: poppedName,
      trackedCurrentRouteName: _pageCubit.state.currentRouteName,
    )) {
      onRouteChanged(previousRoute);
    }
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
    if ((route.settings.name ?? '').isEmpty && _pagesUnderOverlays.isNotEmpty) {
      // Removed rather than popped — drop the entry so a later overlay does not
      // restore a page name from a route that is long gone.
      _pagesUnderOverlays.removeLast();
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

@LazySingleton(as: NavigatorObserver)
@Named(DIKey.habitRouterObserver)
class HabitRouterObserver extends BaseRouterObserver {
  HabitRouterObserver(
    PageCubit pageCubit,
  ) : super('HabitRouterObserver', pageCubit);
}

@LazySingleton(as: NavigatorObserver)
@Named(DIKey.libraryRouterObserver)
class LibraryRouterObserver extends BaseRouterObserver {
  LibraryRouterObserver(
    PageCubit pageCubit,
  ) : super('LibraryRouterObserver', pageCubit);
}
