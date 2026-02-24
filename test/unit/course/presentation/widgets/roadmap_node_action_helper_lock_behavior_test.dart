import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('RoadmapNodeActionHelper.resolveLessonLockAction', () {
    test('returns ignoreTap for locked notStarted lesson', () {
      final action = RoadmapNodeActionHelper.resolveLessonLockAction(
        isLocked: true,
        progress: ProcessEnum.notStarted,
      );

      expect(action, LessonLockAction.ignoreTap);
    });

    test('returns showPaywall for locked inProgress lesson', () {
      final action = RoadmapNodeActionHelper.resolveLessonLockAction(
        isLocked: true,
        progress: ProcessEnum.inProgress,
      );

      expect(action, LessonLockAction.showPaywall);
    });

    test('returns proceed for locked done lesson', () {
      final action = RoadmapNodeActionHelper.resolveLessonLockAction(
        isLocked: true,
        progress: ProcessEnum.done,
      );

      expect(action, LessonLockAction.proceed);
    });

    test('returns proceed for unlocked inProgress lesson', () {
      final action = RoadmapNodeActionHelper.resolveLessonLockAction(
        isLocked: false,
        progress: ProcessEnum.inProgress,
      );

      expect(action, LessonLockAction.proceed);
    });
  });
}
