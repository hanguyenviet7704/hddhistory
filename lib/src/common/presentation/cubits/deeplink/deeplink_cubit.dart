part of '../../../common.dart';

@lazySingleton
class DeeplinkCubit extends Cubit<DeeplinkState> {
  final IDeepLinkService _deepLinkService;
  DeeplinkCubit(this._deepLinkService) : super(DeeplinkState.initial()) {
    init();
  }

  StreamSubscription<Uri?>? _homeWidgetClickSubscription;
  StreamSubscription<NotificationInteraction>? _notificationInteractionSubscription;
  String _serviceRoutePath = '';
  String _pendingUriKey = '';
  String _lastHandledInitialUriKey = '';
  Map<String, String> _serviceRouteQuery = {};

  void init() {
    _deepLinkService.uriStream.listen(
      (uri) => navigationFromService(uri),
      onDone: () {
        // _deepLinkService.uriStream.drain();
      },
      onError: (error, stackTrace) => LogDev.one('navigationFromService error: $error, stackTrace: $stackTrace'),
    );
    _homeWidgetClickSubscription = home_widget_plugin.HomeWidget.widgetClicked.listen(
      (uri) {
        if (uri == null) return;
        navigationFromService(uri);
      },
      onError: (error, stackTrace) => LogDev.one('homeWidgetClicked error: $error, stackTrace: $stackTrace'),
    );
    // Live Activity return-nudge taps arrive as notification interactions, not
    // deeplink URIs, so bridge them here — mirrors the home-widget click
    // subscription above. Only the one nudge id is acted on; everything else is
    // ignored inside the handler.
    _notificationInteractionSubscription = NotificationService.interactionStream.listen(
      _handleNotificationInteraction,
      onError: (error, stackTrace) => LogDev.one('notificationInteraction error: $error, stackTrace: $stackTrace'),
    );
  }

  void resetServiceRouteData() {
    _serviceRoutePath = '';
    _pendingUriKey = '';
    _serviceRouteQuery = {};
  }

  bool setIsPassSplashScreen(bool isPassSplashScreen) {
    if (state.isPassSplashScreen != isPassSplashScreen) {
      emit(state.copyWith(isPassSplashScreen: isPassSplashScreen));
    }

    if (!isPassSplashScreen) return false;
    return handleRoute();
  }

  bool navigationFromService(Uri uri) {
    try {
      _resolveServiceLink(uri);
      return handleRoute();
    } catch (error, stackTrace) {
      LogDev.error('navigationFromService failed: $error\r\n$stackTrace');
      resetServiceRouteData();
      return false;
    }
  }

  Future<bool> initialLink() async {
    try {
      Uri? uri = await _deepLinkService.getInitialLink();
      if (uri != null && _lastHandledInitialUriKey == uri.toString()) {
        LogDev.info('Skipping duplicate initial deeplink: $uri');
        return false;
      }
      if (uri != null && navigationFromService(uri)) return true;

      // The home_widget plugin requires the iOS app-group id to be set before
      // any other call in the session; otherwise this throws
      // PlatformException(-7, "AppGroupId not set") on every cold start,
      // breaking launch-from-widget deeplinks (the widget bridge only sets it
      // when a widget sync runs, which is too late for this path).
      await home_widget_plugin.HomeWidget.setAppGroupId(HomeWidgetAppGroups.current());
      uri = await home_widget_plugin.HomeWidget.initiallyLaunchedFromHomeWidget();
      if (uri == null) return false;
      if (_lastHandledInitialUriKey == uri.toString()) {
        LogDev.info('Skipping duplicate initial home widget deeplink: $uri');
        return false;
      }
      return navigationFromService(uri);
    } catch (error, stackTrace) {
      LogDev.error('initialLink failed: $error\r\n$stackTrace');
      resetServiceRouteData();
      return false;
    }
  }

  bool handleRoute() {
    if (!state.isPassSplashScreen || _serviceRoutePath.isEmpty) return false;
    _handleServiceRouteParam();
    final isHandled = _handleLiveActivityRoute() || _handleShellRoute() || _handleNormalRoute();
    if (isHandled) {
      _lastHandledInitialUriKey = _pendingUriKey;
    }
    if (!isHandled) {
      LogDev.warning('Ignoring unsupported deeplink route: $_serviceRoutePath');
    }
    resetServiceRouteData();
    return isHandled;
  }

  bool _handleShellRoute() {
    final target = HomeWidgetDeeplinkTarget.tryParse(Uri(path: _serviceRoutePath, queryParameters: _serviceRouteQuery));
    if (target == null) return false;
    return _handleHomeWidgetRoute(target);
  }

  bool _handleNormalRoute() {
    switch (_serviceRoutePath) {
      case RoutePath.home:
        final navContext = AppConfig.instance.context;
        if (navContext == null) {
          LogDev.warning('Ignoring deeplink because navigator context is unavailable');
          return false;
        }
        HomeRoute().go(navContext);
        return true;
      default:
        return false;
    }
  }

  bool _handleHomeWidgetRoute(HomeWidgetDeeplinkTarget target) {
    final navContext = AppConfig.instance.context;
    if (navContext == null) {
      LogDev.warning('Ignoring home widget deeplink because navigator context is unavailable');
      _trackHomeWidgetRoute(target, TrackingKey.homeWidgetDeeplinkFailure, reason: 'missing_context');
      return false;
    }

    _trackHomeWidgetRoute(target, TrackingKey.homeWidgetTap);

    if (target.routePath == RoutePath.home) {
      HomeRoute().go(navContext);
      _trackHomeWidgetRoute(target, TrackingKey.homeWidgetDeeplinkSuccess, resolvedRoute: RoutePath.home);
      return true;
    }

    if (target.routePath != RoutePath.courseRoadmap) return false;

    if (!_openCourseRoadmap(navContext, target.courseId, HomeWidgetDeeplinkTarget.sourceValue)) {
      HomeRoute().go(navContext);
      _trackHomeWidgetRoute(target, TrackingKey.homeWidgetDeeplinkFailure, reason: 'course_not_found', resolvedRoute: RoutePath.home);
      return true;
    }
    _trackHomeWidgetRoute(target, TrackingKey.homeWidgetDeeplinkSuccess, resolvedRoute: RoutePath.courseRoadmap);
    return true;
  }

  /// Navigates to the roadmap for [courseId], selecting it in HomeCubit first
  /// (the SAME sequence the home_widget→course deeplink uses). [source] tags the
  /// roadmap for back-nav/analytics. Returns false only when a non-empty course
  /// can't be selected, so callers can fall back to Home.
  bool _openCourseRoadmap(BuildContext navContext, String? courseId, String source) {
    if (courseId?.isNotEmpty == true) {
      final isSelected = AppDI.injector.get<HomeCubit>().trySelectCourseFromCourseId(courseId!);
      if (!isSelected) return false;
    }
    AppDI.injector.get<CourseRoadmapCubit>().setRoadmapSource(source);
    // Not just setCurrentIndex(1) — see course_card.dart's identical fix.
    AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
    CourseRoadmapRoute().go(navContext);
    return true;
  }

  /// The iOS Live Activity lock-screen card opens
  /// `meup://course-roadmap?courseId=…&source=live_activity`. That source is NOT
  /// a home-widget deeplink (it carries no widgetType), so
  /// [HomeWidgetDeeplinkTarget.tryParse] rejects it — before this branch the tap
  /// was logged as an unsupported route and the resume silently no-op'd. Here we
  /// navigate to the roadmap AND fire `live_resume_tap`.
  bool _handleLiveActivityRoute() {
    if (_serviceRoutePath != RoutePath.courseRoadmap) return false;
    if (_serviceRouteQuery[LiveActivityDeeplink.sourceQueryKey] != LiveActivityDeeplink.sourceValue) return false;

    final courseId = _serviceRouteQuery[LiveActivityDeeplink.courseIdQueryKey]?.trim() ?? '';
    if (!openCourseRoadmapFromLiveActivity(courseId)) return false;

    unawaited(
      AppService.instance.appTrackingService
          .trackEvent(TrackingKey.liveResumeTap, parameters: {'course_id': courseId, 'course_name': _resolveLiveActivityCourseName(courseId)})
          .catchError((_) {}),
    );
    return true;
  }

  /// Resumes the course roadmap for [courseId] the same way the Live Activity
  /// card does — reuses [_openCourseRoadmap] (the home_widget→course path) and
  /// falls back to Home when the course can't be selected. Public so the
  /// return-nudge interaction subscriber drives the identical resume.
  bool openCourseRoadmapFromLiveActivity(String courseId) {
    final navContext = AppConfig.instance.context;
    if (navContext == null) {
      LogDev.warning('Ignoring live activity resume because navigator context is unavailable');
      return false;
    }
    if (!_openCourseRoadmap(navContext, courseId, LiveActivityDeeplink.sourceValue)) {
      HomeRoute().go(navContext);
    }
    return true;
  }

  /// Best-effort course title from the full catalog (never throws / returns ''
  /// for an unknown or not-yet-loaded course), mirroring the habit/tracking
  /// resolvers.
  String _resolveLiveActivityCourseName(String courseId) {
    if (courseId.isEmpty) return '';
    try {
      return AppDI.injector.get<HomeCubit>().state.skillsets.resolveCourseByCourseId(courseId).title.text;
    } catch (_) {
      return '';
    }
  }

  /// Bridges a tap on the Live Activity return nudge to `live_nudge_tap` + the
  /// same resume as the deeplink. Every other notification interaction (push
  /// opens, foreground receipts, other locals) is ignored — the local nudge's
  /// notification id is the only match.
  void _handleNotificationInteraction(NotificationInteraction interaction) {
    final sourceId = int.tryParse(interaction.payload.sourceId ?? '');
    if (sourceId != liveActivityReturnNudgeNotificationId) return;

    final raw = interaction.payload.raw;
    final courseId = (raw['course_id'] ?? '').toString().trim();
    var courseName = (raw['course_name'] ?? '').toString().trim();
    if (courseName.isEmpty) courseName = _resolveLiveActivityCourseName(courseId);

    unawaited(
      AppService.instance.appTrackingService
          .trackEvent(TrackingKey.liveNudgeTap, parameters: {'course_id': courseId, 'course_name': courseName})
          .catchError((_) {}),
    );

    openCourseRoadmapFromLiveActivity(courseId);
  }

  void _trackHomeWidgetRoute(
    HomeWidgetDeeplinkTarget target,
    String eventName, {
    String? reason,
    String? resolvedRoute,
  }) {
    final params = {
      ...target.trackingParams,
      if (reason?.isNotEmpty == true) 'reason': reason,
      if (resolvedRoute?.isNotEmpty == true) 'resolved_route': resolvedRoute,
    };
    unawaited(AppService.instance.appTrackingService.trackEvent(eventName, parameters: params));
  }

  void _resolveServiceLink(Uri uri) {
    LogDev.one('ServiceRoute, uri: $uri');
    final String host = uri.host;
    final String path = uri.path;
    final String query = uri.query;
    final String fragment = uri.fragment;
    final Map<String, String> queryParameters = uri.queryParameters;
    _pendingUriKey = uri.toString();
    _serviceRoutePath = resolveDeeplinkRoutePath(uri);
    _serviceRouteQuery = queryParameters;
    LogDev.one('ServiceRoute, pathValue: $path, query: $query, host: $host, fragment: $fragment, queryParameters: $_serviceRouteQuery');
    LogDev.one('ServiceRoute, pathValueSaved: $_serviceRoutePath, query: $_serviceRouteQuery');
  }

  void _handleServiceRouteParam() {
    _handleServiceRouteHomeTab();
  }

  void _handleServiceRouteHomeTab() {
    if (_serviceRouteQuery['module'] == null) return;
  }

  @override
  Future<void> close() async {
    await _homeWidgetClickSubscription?.cancel();
    await _notificationInteractionSubscription?.cancel();
    return super.close();
  }
}

String resolveDeeplinkRoutePath(Uri uri) {
  final path = uri.path.trim();
  if (path.isNotEmpty && path != RoutePath.home) {
    final normalizedPath = normalizeDeeplinkPath(path);
    return normalizedPath;
  }

  final normalizedHost = uri.host.trim().toLowerCase();
  if (normalizedHost.isEmpty || normalizedHost == 'meup.training') {
    return RoutePath.home;
  }

  if (normalizedHost == 'home') {
    return RoutePath.home;
  }

  return '/$normalizedHost';
}

@visibleForTesting
String normalizeDeeplinkPath(String path) {
  final trimmedPath = path.trim();
  if (trimmedPath.isEmpty || trimmedPath == RoutePath.home || trimmedPath == '/home') {
    return RoutePath.home;
  }

  return trimmedPath.startsWith('/') ? trimmedPath : '/$trimmedPath';
}
