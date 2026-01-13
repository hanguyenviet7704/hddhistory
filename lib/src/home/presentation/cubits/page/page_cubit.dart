part of '../../../home.dart';

@lazySingleton
class PageCubit extends Cubit<PageState> {
  PageCubit() : super(PageState.initial());
  List<String> navigationHistory = [];

  void setCurrentIndex(int index) => emit(state.copyWith(currentIndex: index));
  void addNavigationHistory(String routeName) => navigationHistory.add(routeName);
  void removeNavigationHistory(String routeName) => navigationHistory.remove(routeName);
  void clearNavigationHistory() => navigationHistory.clear();
  void replaceNavigationHistory(String newRouteName, String oldRouteName) => navigationHistory.replaceAt(newRouteName, at: navigationHistory.indexOf(oldRouteName));
  void setIsPassSplashScreen(bool isPassSplashScreen) => emit(state.copyWith(isPassSplashScreen: isPassSplashScreen));
  void setCurrentRouteName(String routeName) => emit(state.copyWith(currentRouteName: routeName));

  void handleShellRouteNavigation(int index, StatefulNavigationShell navigationShell) {
    if (index == state.currentIndex && index == 0 && state.currentRouteName == RouteNamed.home) return;
    if (index == state.currentIndex && index == 1 && state.currentRouteName == RouteNamed.courseRoadmap) return;
    if (index == state.currentIndex && index == 2 && state.currentRouteName == RouteNamed.profile) return;

    switch (index) {
      case 0:
        setCurrentRouteName(RouteNamed.home);
        break;
      case 1:
        setCurrentRouteName(RouteNamed.courseRoadmap);
        break;
      case 2:
        setCurrentRouteName(RouteNamed.profile);
        break;
    }

    _routeNavigationShell(index, navigationShell);
  }

  void _routeNavigationShell(int index, StatefulNavigationShell navigationShell) {
    setCurrentIndex(index);
    navigationShell.goBranch(index);
  }
}
