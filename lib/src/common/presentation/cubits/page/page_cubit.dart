part of '../../../common.dart';

@lazySingleton
class PageCubit extends Cubit<PageState> {
  PageCubit() : super(PageState.initial());
  List<String> navigationHistory = [];

  void setCurrentIndex(int index) {
    final normalizedIndex = _normalizeTabIndex(index);
    if (normalizedIndex == null) return;
    emit(state.copyWith(currentIndex: normalizedIndex));
  }

  void addNavigationHistory(String routeName) => navigationHistory.add(routeName);
  void removeNavigationHistory(String routeName) => navigationHistory.remove(routeName);
  void clearNavigationHistory() => navigationHistory.clear();
  void replaceNavigationHistory(String newRouteName, String oldRouteName) => navigationHistory.replaceAt(newRouteName, at: navigationHistory.indexOf(oldRouteName));
  void setIsPassSplashScreen(bool isPassSplashScreen) => emit(state.copyWith(isPassSplashScreen: isPassSplashScreen));

  void setCurrentRouteName(String routeName) {
    final currentIndex = _tabIndexForRouteName(routeName) ?? state.currentIndex;
    emit(state.copyWith(currentRouteName: routeName, currentIndex: currentIndex));
  }

  void handleShellRouteNavigation(int index, StatefulNavigationShell navigationShell) {
    if (index == state.currentIndex && index == 0 && state.currentRouteName == RouteNamed.home) return;
    if (index == state.currentIndex && index == 1 && state.currentRouteName == RouteNamed.courseRoadmap) return;
    if (index == state.currentIndex && index == 2 && state.currentRouteName == RouteNamed.profile) return;

    final tabType = _tabTypeForIndex(index);
    if (tabType != null) {
      AppService.instance.appTrackingService.trackHomeTabSwitch(tabType);
    }

    switch (index) {
      case 0:
        setCurrentRouteName(RouteNamed.home);
        break;
      case 1:
        AppDI.injector.get<CourseRoadmapCubit>().setRoadmapSource('nav_course');
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

  int? _normalizeTabIndex(int index) {
    if (index < 0 || index > 2) return null;
    return index;
  }

  int? _tabIndexForRouteName(String routeName) {
    switch (routeName) {
      case RouteNamed.home:
        return 0;
      case RouteNamed.course:
      case RouteNamed.courseRoadmap:
        return 1;
      case RouteNamed.profile:
        return 2;
      default:
        return null;
    }
  }

  String? _tabTypeForIndex(int index) {
    switch (index) {
      case 0:
        return 'home';
      case 1:
        return 'progress';
      case 2:
        return 'setting';
      default:
        return null;
    }
  }
}
