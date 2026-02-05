part of '../../../common.dart';

@lazySingleton
class DeeplinkCubit extends Cubit<DeeplinkState> {
  final IDeepLinkService _deepLinkService;
  DeeplinkCubit(this._deepLinkService) : super(DeeplinkState.initial()) {
    init();
  }

  String _serviceRouteName = '';
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
    _serviceRouteName = '';
    _serviceRouteQuery = {};
  }

  void navigationFromService(Uri uri) {
    _resolveServiceLink(uri);
    handleRoute();
  }

  Future<bool> initialLink() async {
    Uri? uri = await _deepLinkService.getInitialLink();
    if (uri == null) return false;
    navigationFromService(uri);
    return true;
  }

  void handleRoute() {
    if (!state.isPassSplashScreen) return;
    _handleServiceRouteParam();
    _handleShellRoute();
    _handleNormalRoute();
    resetServiceRouteData();
  }

  void _handleShellRoute() {
    switch (_serviceRouteName) {
      case RouteNamed.home:
        break;
      // case RouteNamed.vnsShop:
      //   setCurrentIndex(1);
      //   break;
      // case RouteNamed.notification:
      //   setCurrentIndex(3);
      //   break;
      // case RouteNamed.profile:
      //   setCurrentIndex(4);
      //   AppConfig.instance.context!.read<UserCubit>().initProfilePage();
      //   break;
    }
  }

  void _handleNormalRoute() {
    switch (_serviceRouteName) {
      case RoutePath.home:
        HomeRoute().go(AppConfig.instance.context!);
        break;
    }
  }

  void _resolveServiceLink(Uri uri) {
    LogDev.one('ServiceRoute, uri: $uri');
    final String host = uri.host;
    final String path = uri.path;
    final String query = uri.query;
    final String fragment = uri.fragment;
    final Map<String, String> queryParameters = uri.queryParameters;
    _serviceRouteName = path.pathToCamelCase.isEmpty ? RoutePath.home : path.pathToCamelCase;
    _serviceRouteQuery = queryParameters;
    LogDev.one('ServiceRoute, pathValue: ${path.pathToCamelCase}, query: $query, host: $host, fragment: $fragment, queryParameters: $_serviceRouteQuery');
    LogDev.one('ServiceRoute, pathValueSaved: $_serviceRouteName, query: $_serviceRouteQuery');
  }

  void _handleServiceRouteParam() {
    _handleServiceRouteHomeTab();
  }

  void _handleServiceRouteHomeTab() {
    if (_serviceRouteQuery['module'] == null) return;
  }
}
