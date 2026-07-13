part of '../../../common.dart';

@lazySingleton
class PageCubit extends Cubit<PageState> {
  PageCubit() : super(PageState.initial());
  List<String> navigationHistory = [];
  bool _shouldResetHomeBranchOnNextSelection = false;

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
  void requestHomeBranchResetOnNextSelection() => _shouldResetHomeBranchOnNextSelection = true;

  void setCurrentRouteName(String routeName) {
    final currentIndex = _tabIndexForRouteName(routeName) ?? state.currentIndex;
    emit(state.copyWith(currentRouteName: routeName, currentIndex: currentIndex));
  }

  void handleShellRouteNavigation(int index, StatefulNavigationShell navigationShell) {
    if (index == state.currentIndex && index == 0 && state.currentRouteName == RouteNamed.home) return;
    if (index == state.currentIndex && index == 1 && state.currentRouteName == RouteNamed.courseRoadmap) return;
    if (index == state.currentIndex && index == 2 && state.currentRouteName == RouteNamed.profile) return;
    if (index == state.currentIndex && index == 3 && state.currentRouteName == RouteNamed.course) return;
    if (index == state.currentIndex && index == 4 && state.currentRouteName == RouteNamed.habit) return;

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
      case 3:
        // Open Explore scrolled to the section holding the user's current
        // (blue-border) course instead of resetting to the top — so entering
        // the tab lands on "the course you're studying", not a jumpy default.
        // Falls back to the top when nothing is selected (index -1).
        final selectedSkillsetIndex = AppDI.injector.get<HomeCubit>().state.selectedSkillsetIndex;
        AppDI.injector.get<CourseCubit>()
          ..setAllCourseSource('nav_explore')
          ..jumpToSkillset(selectedSkillsetIndex);
        setCurrentRouteName(RouteNamed.course);
        break;
      case 4:
        setCurrentRouteName(RouteNamed.habit);
        break;
    }

    _routeNavigationShell(index, navigationShell);
  }

  void _routeNavigationShell(int index, StatefulNavigationShell navigationShell) {
    final initialLocation = consumeInitialLocationForShellTab(index);
    setCurrentIndex(index);
    navigationShell.goBranch(index, initialLocation: initialLocation);
  }

  @visibleForTesting
  bool consumeInitialLocationForShellTab(int index) {
    if (index != 0 || !_shouldResetHomeBranchOnNextSelection) return false;
    _shouldResetHomeBranchOnNextSelection = false;
    return true;
  }

  int? _normalizeTabIndex(int index) {
    if (index < 0 || index > 4) return null;
    return index;
  }

  int? _tabIndexForRouteName(String routeName) {
    switch (routeName) {
      case RouteNamed.home:
        return 0;
      case RouteNamed.courseRoadmap:
        return 1;
      case RouteNamed.profile:
        return 2;
      case RouteNamed.course:
        return 3;
      case RouteNamed.habit:
        return 4;
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
      case 3:
        return 'explore';
      case 4:
        return 'habit';
      default:
        return null;
    }
  }
}
