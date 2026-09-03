import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('Lesson route config', () {
    test('exposes route path and route name constants', () {
      expect(RoutePath.lesson, 'lesson');
      expect(RouteNamed.lesson, 'Lesson');
    });

    // `initial-mode` is INERT since 2026-08-19 (narration never autoplays —
    // the reader starts it from the keypoint header). The param and its
    // `'read'`/`'audio'` wire values are kept ONLY so deep links built against
    // its two previous meanings (mode tab, then entry-autoplay) keep
    // resolving. These tests pin that wire compatibility, not any behavior.
    test('the plain route carries no initial-mode query', () {
      const route = LessonRoute();

      expect(route.location, '/course-roadmap/lesson');
      expect(route.location, isNot(contains('initial-mode=')));
      expect(LessonEntryMode.fromRouteValue(route.initialMode).isAudio, isTrue);
    });

    test('a link passing the legacy initial-mode still serializes', () {
      const route = LessonRoute(initialMode: 'read');

      expect(route.location, contains('/course-roadmap/lesson'));
      expect(route.location, contains('initial-mode=read'));
    });

    test('legacy initial-mode wire values still parse without crashing', () {
      expect(LessonEntryMode.fromRouteValue('audio').isAudio, isTrue);
      expect(LessonEntryMode.fromRouteValue('listen').isAudio, isFalse);
    });
  });
}
