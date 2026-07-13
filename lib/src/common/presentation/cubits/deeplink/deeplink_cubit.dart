part of '../../../common.dart';

@lazySingleton
class DeeplinkCubit extends Cubit<DeeplinkState> {
  final IDeepLinkService _deepLinkService;
  DeeplinkCubit(this._deepLinkService) : super(DeeplinkState.initial()) {
    init();
  }

  StreamSubscription<Uri?>? _homeWidgetClickSubscription;
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
    final isHandled = _handleShellRoute() || _handleNormalRoute();
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

    final courseId = target.courseId;
    if (courseId?.isNotEmpty == true) {
      final isSelected = AppDI.injector.get<HomeCubit>().trySelectCourseFromCourseId(courseId!);
      if (!isSelected) {
        HomeRoute().go(navContext);
        _trackHomeWidgetRoute(target, TrackingKey.homeWidgetDeeplinkFailure, reason: 'course_not_found', resolvedRoute: RoutePath.home);
        return true;
      }
    }

    AppDI.injector.get<CourseRoadmapCubit>().setRoadmapSource(HomeWidgetDeeplinkTarget.sourceValue);
    // Not just setCurrentIndex(1) — see course_card.dart's identical fix.
    AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
    CourseRoadmapRoute().go(navContext);
    _trackHomeWidgetRoute(target, TrackingKey.homeWidgetDeeplinkSuccess, resolvedRoute: RoutePath.courseRoadmap);
    return true;
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
