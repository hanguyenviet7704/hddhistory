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

      expect(cubit.state.currentIndex, 1);
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
}
