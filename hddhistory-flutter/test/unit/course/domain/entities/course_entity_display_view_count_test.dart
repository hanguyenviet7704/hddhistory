import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  group('CourseEntity.displayViewCount', () {
    test('a coming-soon course claims no reach', () {
      const course = CourseEntity(
        status: CoursePublishStatus.comingSoon,
        viewCount: 6300,
      );

      expect(course.isComingSoonNow, isTrue);
      expect(course.displayViewCount, isNull);
    });

    test('a coming-soon course scheduled for later claims no reach', () {
      final course = CourseEntity(
        status: CoursePublishStatus.comingSoon,
        publishAt: DateTime.now().add(const Duration(days: 3)),
        viewCount: 6300,
      );

      expect(course.displayViewCount, isNull);
    });

    test('a coming-soon course past its publishAt is live and keeps its reach', () {
      final course = CourseEntity(
        status: CoursePublishStatus.comingSoon,
        publishAt: DateTime.now().subtract(const Duration(days: 1)),
        viewCount: 6300,
      );

      expect(course.isComingSoonNow, isFalse);
      expect(course.displayViewCount, 6300);
    });

    test('a published course keeps its reach', () {
      const course = CourseEntity(viewCount: 6300);

      expect(course.displayViewCount, 6300);
    });

    test('a published course with no admin figure stays blank', () {
      const course = CourseEntity();

      expect(course.displayViewCount, isNull);
    });
  });
}
