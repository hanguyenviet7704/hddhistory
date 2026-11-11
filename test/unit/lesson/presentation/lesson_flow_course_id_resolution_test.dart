import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  group('resolveLessonFlowCourseId', () {
    test('prefers the lesson course when it is available', () {
      final courseId = resolveLessonFlowCourseId(
        lessonCourseId: 'lesson-course',
        roadmapCourseId: 'roadmap-course',
        homeCourseId: 'home-course',
      );

      expect(courseId, 'lesson-course');
    });

    test('falls back to the roadmap course when lesson course is missing', () {
      final courseId = resolveLessonFlowCourseId(
        roadmapCourseId: 'roadmap-course',
        homeCourseId: 'home-course',
      );

      expect(courseId, 'roadmap-course');
    });

    test('falls back to the home course when lesson and roadmap courses are missing', () {
      final courseId = resolveLessonFlowCourseId(
        homeCourseId: 'home-course',
      );

      expect(courseId, 'home-course');
    });
  });
}
