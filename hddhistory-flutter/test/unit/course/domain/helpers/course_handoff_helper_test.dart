import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  group('CourseHandoffHelper', () {
    test('valid course prepares roadmap handoff in order', () async {
      final calls = <String>[];

      final intent = await const CourseHandoffHelper().prepareRecommendedCourse(
        course: const CourseEntity(id: 'course_1'),
        initializeHomeData: () async => calls.add('init'),
        selectCourseFromCourseId: (courseId) => calls.add('select:$courseId'),
        loadRoadmap: (courseId) => calls.add('roadmap:$courseId'),
      );

      expect(intent, CourseHandoffRouteIntent.courseRoadmap);
      expect(calls, ['init', 'select:course_1', 'roadmap:course_1']);
    });

    test('handoff failure falls back to course page intent', () async {
      final intent = await const CourseHandoffHelper().prepareRecommendedCourse(
        course: const CourseEntity(id: 'course_1'),
        initializeHomeData: () async {},
        selectCourseFromCourseId: (_) => throw StateError('missing course'),
        loadRoadmap: (_) {},
      );

      expect(intent, CourseHandoffRouteIntent.course);
    });

    test('choose-myself handoff initializes course catalog', () async {
      var didInitialize = false;

      final intent = await const CourseHandoffHelper().prepareCourseCatalog(
        initializeHomeData: () async => didInitialize = true,
      );

      expect(intent, CourseHandoffRouteIntent.course);
      expect(didInitialize, isTrue);
    });
  });
}
