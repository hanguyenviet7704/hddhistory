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

  /// Track the route the reader is standing on.
  ///
  /// An empty name is stored AS empty, and that is deliberate. It was briefly
  /// resolved to the active branch's root instead, to stop the floating nav
  /// vanishing on a tab after a sub-page was popped — and that broke far more
  /// than it fixed: an unnamed route is also what a dismissed overlay reports,
  /// so the nav appeared over the lesson reader and over habit detail, on top of
  /// their own dialogs. Blank means "not a primary route", and hiding the nav is
  /// the safe direction to fail in. Pages that need the name restored on the way
  /// out say so themselves — see `LessonPage._ensureLessonRouteName` and the
  /// back handlers in My Creations and the user-lesson roadmap.
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
        // Open Explore at the TOP — the search field and the import board
        // first, then the sections.
        //
        // This used to jump to the section holding the reader's current
        // (blue-border) course, so the tab landed on "what you're studying".
        // That worked while the search field and the import board were pinned
        // ABOVE the scroll view: you got both, the header and your section.
        // Once they moved INTO the list (2026-09-05) the jump started scrolling
        // them off the top, so tapping Khám phá opened on a bare section with
        // no way to search and no board — the reader's two reasons for coming
        // here (owner, 2026-09-05: "bấm vào nav khám phá bị cuộn lên như này").
        //
        // Deep links are unaffected: Home's progress tiles and "Xem tất cả" set
        // their target through CourseCubit directly and never come through
        // here.
        AppDI.injector.get<CourseCubit>()
          ..setAllCourseSource('nav_explore')
          ..resetExploreToAll();
        setCurrentRouteName(RouteNamed.course);
        break;
      case 4:
        setCurrentRouteName(RouteNamed.habit);
        break;
      case 5:
        setCurrentRouteName(RouteNamed.library);
        break;
      case 6:
        // Confession. Missing until now, and that omission is what put the AI
        // Coach bubble on top of the chat button: with no case here the tab tap
        // claimed nothing, so `currentRouteName` stayed on whatever tab the
        // reader came FROM — Home, most of the time — and the Coach renders for
        // exactly that name. CommunityPage claims it too, but only in initState
        // and on an index change, and neither fires when an already-built
        // branch is re-entered.
        setCurrentRouteName(RouteNamed.community);
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
    if (index < 0 || index > 5) return null;
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
      case RouteNamed.community:
        return 6;
      // Every route that lives in the Library branch resolves to it, not just
      // its root: My Creations and the generated-lesson roadmap are entered by
      // a cross-branch `.go()` from the lesson flow, and that go fires no
      // didPush in an already-built branch — so the name is the only signal
      // that the shell has moved to branch 5.
      case RouteNamed.library:
      case RouteNamed.libraryHistory:
      case RouteNamed.myLessons:
      case RouteNamed.lessonReader:
        return 5;
      default:
        return null;
    }
  }

}

/// Whether a full-screen page may (re-)assert its OWN route name over whatever
/// the route observer last wrote.
///
/// [isRouteCurrent] — the page is still the top route of its own navigator.
/// [isBranchOnScreen] — the shell branch it lives in is the one being displayed.
///
/// Both are required, and the second is the one that keeps being forgotten. A
/// page inside a shell branch is NOT popped when the reader moves to a DIFFERENT
/// branch — `StatefulShellRoute.indexedStack` keeps every branch alive — so
/// `isCurrent` stays true while the page sits offscreen. A page that reclaims on
/// that alone steals the VISIBLE branch's route name, and because the stolen
/// name is non-primary the shell's floating nav vanishes on a tab the reader is
/// plainly standing on, with no way to get it back (reported for a generated
/// lesson: read it, leave its roadmap, land on Profile with no nav — the reader
/// page was still `isCurrent` in the backgrounded course branch and took the
/// name back the moment `Profile` landed).
@visibleForTesting
bool shouldAssertOwnRouteName({
  required bool isRouteCurrent,
  required bool isBranchOnScreen,
}) => isRouteCurrent && isBranchOnScreen;

/// [shouldAssertOwnRouteName] answered from the page's own context.
///
/// go_router wraps an inactive branch in `TickerMode(enabled: false)` (see
/// `_IndexedStackedRouteBranchContainer`), which is the cheapest truthful answer
/// to "is my branch the one on screen?" — no shell lookup, no mirrored state.
bool canAssertOwnRouteName(BuildContext context) => shouldAssertOwnRouteName(
  isRouteCurrent: ModalRoute.of(context)?.isCurrent ?? false,
  isBranchOnScreen: TickerMode.valuesOf(context).enabled,
);

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
