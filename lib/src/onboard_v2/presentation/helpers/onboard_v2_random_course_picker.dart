part of '../../onboard_v2.dart';

abstract final class OnboardV2RandomCoursePicker {
  static List<CourseEntity> pick(
    List<CourseEntity> courses, {
    required int Function(int max) nextInt,
    int maxCourses = 3,
  }) {
    final eligibleCourses = _eligibleCourses(courses);
    if (eligibleCourses.isEmpty || maxCourses <= 0) return const [];
    if (eligibleCourses.length == 1) return eligibleCourses;

    final shuffledCourses = List<CourseEntity>.from(eligibleCourses);
    for (var index = shuffledCourses.length - 1; index > 0; index--) {
      final swapIndex = nextInt(index + 1).clamp(0, index);
      final current = shuffledCourses[index];
      shuffledCourses[index] = shuffledCourses[swapIndex];
      shuffledCourses[swapIndex] = current;
    }

    return shuffledCourses.take(maxCourses).toList();
  }

  static List<CourseEntity> _eligibleCourses(List<CourseEntity> courses) {
    final seenIds = <String>{};
    final eligibleCourses = <CourseEntity>[];

    for (final course in courses) {
      final id = course.id.trim();
      if (id.isEmpty || course.numberOfLesson <= 0 || !seenIds.add(id)) continue;
      eligibleCourses.add(course.copyWith(id: id));
    }

    return eligibleCourses;
  }
}
