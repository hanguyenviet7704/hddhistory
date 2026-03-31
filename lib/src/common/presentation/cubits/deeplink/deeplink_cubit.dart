part of '../../../common.dart';

@lazySingleton
class DeeplinkCubit extends Cubit<DeeplinkState> {
  final IDeepLinkService _deepLinkService;
  DeeplinkCubit(this._deepLinkService) : super(DeeplinkState.initial()) {
    init();
  }

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
      if (uri == null) return false;
      if (_lastHandledInitialUriKey == uri.toString()) {
        LogDev.info('Skipping duplicate initial deeplink: $uri');
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
    return false;
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
}

@visibleForTesting
String resolveDeeplinkRoutePath(Uri uri) {
  final normalizedPath = normalizeDeeplinkPath(uri.path);
  if (normalizedPath.isNotEmpty) {
    return normalizedPath;
  }

  final normalizedHost = uri.host.trim().toLowerCase();
  if (normalizedHost.isEmpty) {
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
