import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('OnboardV2RandomCoursePicker', () {
    test('returns null for an empty course list', () {
      expect(
        OnboardV2RandomCoursePicker.pick(
          const [],
          nextInt: (_) => 0,
        ),
        isNull,
      );
    });

    test('returns the only course without using random', () {
      const course = CourseEntity(id: 'course_1');

      expect(
        OnboardV2RandomCoursePicker.pick(
          const [course],
          nextInt: (_) => throw StateError('random should not be called'),
        ),
        course,
      );
    });

    test('uses injected random for deterministic multi-course selection', () {
      const courses = [
        CourseEntity(id: 'course_1'),
        CourseEntity(id: 'course_2'),
        CourseEntity(id: 'course_3'),
      ];

      expect(
        OnboardV2RandomCoursePicker.pick(
          courses,
          nextInt: (max) {
            expect(max, 3);
            return 1;
          },
        )?.id,
        'course_2',
      );
    });
  });
}
