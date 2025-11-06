part of 'di.dart';

@module
abstract class RouteObserverModule {
  @Named(DIKey.rootNavigatorKey)
  @lazySingleton
  GlobalKey<NavigatorState> get rootNavigatorKey => GlobalKey<NavigatorState>();

  @Named(DIKey.shellNavigatorKey)
  @lazySingleton
  GlobalKey<NavigatorState> get shellNavigatorKey => GlobalKey<NavigatorState>();
  @Named(DIKey.appRouterObserver)
  @lazySingleton
  NavigatorObserver get appRouterObserver => AppRouterObserver();

  @Named(DIKey.homeRouterObserver)
  @lazySingleton
  NavigatorObserver get homeRouterObserver => HomeRouterObserver();

  @Named(DIKey.courseRouterObserver)
  @lazySingleton
  NavigatorObserver get shopRouterObserver => ShopRouterObserver();

  @Named(DIKey.settingRouterObserver)
  @lazySingleton
  NavigatorObserver get createPostRouterObserver => CreatePostRouterObserver();
}
