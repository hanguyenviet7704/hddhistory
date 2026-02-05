part of 'di.dart';

@module
abstract class RouteObserverModule {
  @Named(DIKey.rootNavigatorKey)
  @lazySingleton
  GlobalKey<NavigatorState> get rootNavigatorKey => GlobalKey<NavigatorState>();

  @Named(DIKey.shellNavigatorKey)
  @lazySingleton
  GlobalKey<NavigatorState> get shellNavigatorKey => GlobalKey<NavigatorState>();
}
