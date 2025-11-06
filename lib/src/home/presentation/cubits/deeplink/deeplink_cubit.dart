part of '../../../home.dart';

@lazySingleton
class DeeplinkCubit extends Cubit<DeeplinkState> {
  final IDeepLinkService _deepLinkService;
  DeeplinkCubit(this._deepLinkService) : super(DeeplinkState.initial()) {
    init();
  }

  String _serviceRouteName = '';
  Map<String, String> _serviceRouteQuery = {};
  List<String> navigationHistory = [];

  void init() {
    _deepLinkService.uriStream.listen(
      (uri) => navigationFromService(uri),
      onDone: () {
        // _deepLinkService.uriStream.drain();
      },
      onError: (error, stackTrace) => LogDev.one('navigationFromService error: $error, stackTrace: $stackTrace'),
    );
  }

  void addNavigationHistory(String routeName) => navigationHistory.add(routeName);
  void removeNavigationHistory(String routeName) => navigationHistory.remove(routeName);
  void clearNavigationHistory() => navigationHistory.clear();
  void replaceNavigationHistory(String newRouteName, String oldRouteName) => navigationHistory.replaceAt(newRouteName, at: navigationHistory.indexOf(oldRouteName));

  void setCurrentRouteName(String routeName) => emit(state.copyWith(currentRouteName: routeName));
  void setIsPassSplashScreen(bool isPassSplashScreen) => emit(state.copyWith(isPassSplashScreen: isPassSplashScreen));

  void resetServiceRouteData() {
    _serviceRouteName = '';
    _serviceRouteQuery = {};
  }

  void handleNavigation(int index, StatefulNavigationShell navigationShell) {
    if (index != 0 && !state.isAuthenticated) {
      return;
    }

    if (index == 2) {
      return;
    }

    switch (index) {
      case 0:
        setCurrentRouteName(RouteNamed.home);
        break;
      case 1:
        // setCurrentRouteName(RouteNamed.vnsShop);
        break;
      case 3:
        // setCurrentRouteName(RouteNamed.notification);
        break;
      case 4:
        // setCurrentRouteName(RouteNamed.profile);
        AppConfig.instance.context!.read<UserCubit>().initProfilePage();
        break;
    }

    navigationShell.goBranch(index);
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
