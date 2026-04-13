import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('VideoLesson route config', () {
    test('exposes route path and route name constants', () {
      expect(RoutePath.videoLesson, 'video-lesson/:courseId/:nodeId/:lessonId');
      expect(RouteNamed.videoLesson, 'Video Lesson');
    });

    test('builds typed location with course, node, and lesson segments', () {
      const route = VideoLessonRoute(
        courseId: 'course-1',
        nodeId: 'node-1',
        lessonId: 'lesson-1',
      );

      expect(route.location, contains('video-lesson/course-1/node-1/lesson-1'));
      expect(route.location, contains('/course-roadmap/'));
    });
  });
}
