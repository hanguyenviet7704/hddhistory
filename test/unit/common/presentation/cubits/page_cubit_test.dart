import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('PageCubit', () {
    late PageCubit cubit;

    setUp(() {
      cubit = PageCubit();
    });

    tearDown(() async {
      await cubit.close();
    });

    test('syncs bottom tab index from primary route names', () {
      cubit.setCurrentRouteName(RouteNamed.home);
      expect(cubit.state.currentIndex, 0);

      cubit.setCurrentRouteName(RouteNamed.courseRoadmap);
      expect(cubit.state.currentIndex, 1);

      cubit.setCurrentRouteName(RouteNamed.profile);
      expect(cubit.state.currentIndex, 2);
    });

    test('maps standalone course route to course tab for onboarding handoff', () {
      cubit.setCurrentRouteName(RouteNamed.course);

      // The standalone course grid lives in the Explore shell branch, appended
      // last as branch index 3 (see routes_shell.dart) — not 1 (that's the
      // course-roadmap branch).
      expect(cubit.state.currentIndex, 3);
    });

    test('keeps current tab when nested route has no bottom-tab mapping', () {
      cubit.setCurrentRouteName(RouteNamed.courseRoadmap);
      cubit.setCurrentRouteName(RouteNamed.lesson);

      expect(cubit.state.currentRouteName, RouteNamed.lesson);
      expect(cubit.state.currentIndex, 1);
    });

    test('ignores invalid bottom tab indices', () {
      cubit.setCurrentRouteName(RouteNamed.profile);
      cubit.setCurrentIndex(9);

      expect(cubit.state.currentIndex, 2);
    });

    test('preserves home branch state by default', () {
      expect(cubit.consumeInitialLocationForShellTab(0), isFalse);
      expect(cubit.consumeInitialLocationForShellTab(1), isFalse);
      expect(cubit.consumeInitialLocationForShellTab(2), isFalse);
    });

    test('consumes one home branch reset after daily warm-up handoff', () {
      cubit.requestHomeBranchResetOnNextSelection();

      expect(cubit.consumeInitialLocationForShellTab(1), isFalse);
      expect(cubit.consumeInitialLocationForShellTab(0), isTrue);
      expect(cubit.consumeInitialLocationForShellTab(0), isFalse);
    });
  });

  group('shouldIgnoreShellTabTap', () {
    test('ignores a tap on the branch already active', () {
      expect(shouldIgnoreShellTabTap(tappedIndex: 4, activeBranchIndex: 4), isTrue);
      expect(shouldIgnoreShellTabTap(tappedIndex: 0, activeBranchIndex: 0), isTrue);
    });

    // Regression: entering Habit (branch 4) from Home via HabitRoute().go()
    // leaves PageCubit's mirrored state stale on Home (0). Tapping the Home nav
    // tab must still switch branches — the decision keys off the shell's real
    // active branch (4), not the stale mirror — so tapping Home (0) is NOT a
    // no-op and the user can leave the Habit tab.
    test('does not ignore Home tap while Habit branch is active', () {
      expect(shouldIgnoreShellTabTap(tappedIndex: 0, activeBranchIndex: 4), isFalse);
    });

    test('does not ignore a tap toward any different branch', () {
      expect(shouldIgnoreShellTabTap(tappedIndex: 2, activeBranchIndex: 4), isFalse);
      expect(shouldIgnoreShellTabTap(tappedIndex: 4, activeBranchIndex: 0), isFalse);
      expect(shouldIgnoreShellTabTap(tappedIndex: 3, activeBranchIndex: 1), isFalse);
    });
  });
}
