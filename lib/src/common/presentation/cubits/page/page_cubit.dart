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
    // Ignore a tap on the tab that's already showing. Trust the SHELL's active
    // branch (the source of truth), NOT PageCubit's mirrored state: entering a
    // branch via a raw `.go()` (e.g. Home's "Thói quen hôm nay" tile →
    // HabitRoute().go()) re-activates an already-built branch WITHOUT a didPush,
    // so the branch's router observer never runs and currentIndex/
    // currentRouteName stay stale on the PREVIOUS tab. The old guard compared
    // the tapped index against that stale mirror and would then swallow the tap
    // back to the previous tab (reported: enter Habit from Home, then the Home
    // nav tab does nothing — stuck on Habit). The floating nav is only visible
    // on primary (branch-root) routes, so index == active branch always means
    // "tapped the current tab at its root" → a genuine no-op.
    if (shouldIgnoreShellTabTap(tappedIndex: index, activeBranchIndex: navigationShell.currentIndex)) {
      return;
    }

    switch (index) {
      case 0:
        setCurrentRouteName(RouteNamed.home);
        break;
      case 1:
        // Not reachable via a bottom-nav tab tap: ScaffoldLayout never maps a
        // visual tab to branch 1 (the course roadmap) — tapping Khám phá
        // always targets branch 3 (the Explore grid), so the roadmap is only
        // entered by tapping a specific course. Kept for completeness/in case
        // a future caller routes here directly; deliberately does NOT reset
        // the roadmap source so an already-open roadmap keeps whatever source
        // it was opened with (e.g. its back-to-Explore button).
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

}

/// Whether a bottom-nav tab tap should be ignored as a no-op.
///
/// Compares the tapped branch against the shell's ACTUAL active branch
/// ([StatefulNavigationShell.currentIndex]) — never [PageCubit.state], whose
/// currentIndex/currentRouteName can lag behind when a branch is entered via a
/// raw `.go()` (re-activating an already-built branch fires no didPush, so the
/// router observer never syncs the state). Only a tap on the branch already on
/// screen is a no-op; any tap toward a different branch must proceed.
@visibleForTesting
bool shouldIgnoreShellTabTap({
  required int tappedIndex,
  required int activeBranchIndex,
}) => tappedIndex == activeBranchIndex;
