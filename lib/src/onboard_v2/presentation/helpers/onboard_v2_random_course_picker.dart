part of '../../onboard_v2.dart';

abstract final class OnboardV2RandomCoursePicker {
  static CourseEntity? pick(
    List<CourseEntity> courses, {
    required int Function(int max) nextInt,
  }) {
    if (courses.isEmpty) return null;
    if (courses.length == 1) return courses.first;

    final index = nextInt(courses.length);
    return courses[index.clamp(0, courses.length - 1)];
  }
}
