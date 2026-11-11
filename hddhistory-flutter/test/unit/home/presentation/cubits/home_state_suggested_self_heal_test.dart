import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  group('shouldEnsureSuggestedCoursesReload', () {
    test('true when no suggested courses are loaded (failed/skipped first load)', () {
      expect(shouldEnsureSuggestedCoursesReload(HomeState()), isTrue);
    });

    test('false when suggested courses are present (no-op on normal mounts)', () {
      final loaded = HomeState(
        suggestedCourses: [SuggestedCourseEntity()],
      );
      expect(shouldEnsureSuggestedCoursesReload(loaded), isFalse);
    });
  });
}
