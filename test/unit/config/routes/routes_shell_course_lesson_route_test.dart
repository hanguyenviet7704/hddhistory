import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('Lesson route config', () {
    test('exposes route path and route name constants', () {
      expect(RoutePath.lesson, 'lesson');
      expect(RouteNamed.lesson, 'Lesson');
    });

    test('omits the initial-mode query for the default read entry', () {
      const route = LessonRoute();

      expect(route.location, '/course-roadmap/lesson');
      expect(route.location, isNot(contains('initial-mode=')));
    });

    test('adds the initial-mode query for listen entry', () {
      const route = LessonRoute(initialMode: 'audio');

      expect(route.location, contains('/course-roadmap/lesson'));
      expect(route.location, contains('initial-mode=audio'));
    });
  });
}
