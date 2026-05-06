part of '../../onboard_v2.dart';

abstract final class OnboardV2RandomCoursePicker {
  static CourseEntity? pick(
    List<CourseEntity> courses, {
    required int Function(int max) nextInt,
  }) {
    final eligibleCourses = courses.where((course) => course.numberOfLesson > 0).toList();
    if (eligibleCourses.isEmpty) return null;
    if (eligibleCourses.length == 1) return eligibleCourses.first;

    final index = nextInt(eligibleCourses.length);
    return eligibleCourses[index.clamp(0, eligibleCourses.length - 1)];
  }
}
