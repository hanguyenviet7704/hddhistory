import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('shouldEnsureMyCoursesReload', () {
    ProgressState stateWith({
      List<CourseEntity> myCourses = const [],
      ProgressStatus status = ProgressStatus.initial,
    }) {
      return ProgressState(
        status: status,
        myCoursesPageData: BasePageBreak<CourseEntity>(items: myCourses),
      );
    }

    test('true when my-courses is empty and nothing is loading (failed/skipped first load)', () {
      expect(shouldEnsureMyCoursesReload(stateWith()), isTrue);
      expect(
        shouldEnsureMyCoursesReload(stateWith(status: ProgressStatus.failure)),
        isTrue,
      );
    });

    test('false while a load is in flight (no duplicate fetch)', () {
      expect(
        shouldEnsureMyCoursesReload(stateWith(status: ProgressStatus.loading)),
        isFalse,
      );
    });

    test('false when my-courses is already loaded (no-op on normal mounts)', () {
      final loaded = stateWith(
        myCourses: [CourseEntity(id: 'course-1')],
        status: ProgressStatus.success,
      );
      expect(shouldEnsureMyCoursesReload(loaded), isFalse);
    });
  });
}
