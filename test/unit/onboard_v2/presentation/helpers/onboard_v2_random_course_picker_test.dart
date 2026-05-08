import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('OnboardV2RandomCoursePicker', () {
    test('returns empty list for an empty course list', () {
      expect(
        OnboardV2RandomCoursePicker.pick(
          const [],
          nextInt: (_) => 0,
        ),
        isEmpty,
      );
    });

    test('returns empty list when all courses are invalid', () {
      expect(
        OnboardV2RandomCoursePicker.pick(
          const [
            CourseEntity(id: '', numberOfLesson: 2),
            CourseEntity(id: 'course_1', numberOfLesson: 0),
            CourseEntity(id: 'course_2', numberOfLesson: -1),
          ],
          nextInt: (_) => throw StateError('random should not be called'),
        ),
        isEmpty,
      );
    });

    test('returns the only valid course without using random', () {
      const course = CourseEntity(id: 'course_1', numberOfLesson: 1);

      expect(
        OnboardV2RandomCoursePicker.pick(
          const [course],
          nextInt: (_) => throw StateError('random should not be called'),
        ).single,
        course,
      );
    });

    test('excludes courses with empty ids and zero or negative lesson counts', () {
      const courses = [
        CourseEntity(id: '', numberOfLesson: 2),
        CourseEntity(id: 'course_1', numberOfLesson: 0),
        CourseEntity(id: 'course_2', numberOfLesson: 2),
        CourseEntity(id: 'course_3', numberOfLesson: -1),
      ];

      expect(
        OnboardV2RandomCoursePicker.pick(
          courses,
          nextInt: (_) => throw StateError('random should not be called'),
        ).single.id,
        'course_2',
      );
    });

    test('uses injected random for deterministic max-three course selection', () {
      const courses = [
        CourseEntity(id: 'course_1', numberOfLesson: 1),
        CourseEntity(id: 'course_2', numberOfLesson: 2),
        CourseEntity(id: 'course_3', numberOfLesson: 3),
        CourseEntity(id: 'course_4', numberOfLesson: 4),
      ];
      final randomValues = [2, 0, 1];

      expect(
        OnboardV2RandomCoursePicker.pick(
          courses,
          nextInt: (max) {
            expect(max, greaterThan(0));
            return randomValues.removeAt(0);
          },
        ).map((course) => course.id),
        ['course_4', 'course_2', 'course_1'],
      );
    });
  });
}
