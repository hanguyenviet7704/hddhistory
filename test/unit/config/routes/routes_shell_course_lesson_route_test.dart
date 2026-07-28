import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('Lesson route config', () {
    test('exposes route path and route name constants', () {
      expect(RoutePath.lesson, 'lesson');
      expect(RouteNamed.lesson, 'Lesson');
    });

    // `initial-mode` used to pick which mode tab (Read/Listen) the old
    // dual-mode split opened into. The unified keypoint screen has no mode
    // tabs left, so it's repurposed to mean "should the first keypoint's
    // narration autoplay the instant this page mounts" (see `LessonPage`).
    // The wire values/route shape are deliberately unchanged (still
    // `'read'`/`'audio'`, default still omits the query param entirely) so
    // legacy/deep links built against the old meaning keep resolving.
    test('omits the initial-mode query when narration should not autoplay on entry', () {
      const route = LessonRoute();

      expect(route.location, '/course-roadmap/lesson');
      expect(route.location, isNot(contains('initial-mode=')));
    });

    test('adds the initial-mode query when narration should autoplay on entry', () {
      const route = LessonRoute(initialMode: 'audio');

      expect(route.location, contains('/course-roadmap/lesson'));
      expect(route.location, contains('initial-mode=audio'));
    });

    test('a legacy initial-mode=audio deep link resolves to autoplay-on-entry, not a mode tab', () {
      final mode = LessonEntryMode.fromRouteValue('audio');

      expect(mode.isAudio, isTrue);
    });

    test('an unrecognized/legacy initial-mode value falls back to no-autoplay, not a crash', () {
      final mode = LessonEntryMode.fromRouteValue('listen');

      expect(mode.isAudio, isFalse);
    });
  });
}
