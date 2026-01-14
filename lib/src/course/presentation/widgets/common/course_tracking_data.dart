part of '../../../course.dart';

class CourseTrackingData {
  final SkillsetEntity skillset;
  final CourseEntity course;

  const CourseTrackingData({
    required this.skillset,
    required this.course,
  });

  static CourseTrackingData? fromCourseId(BuildContext context, String courseId) {
    final homeState = context.read<HomeCubit>().state;
    final skillset = homeState.skillsets.resolveSkillsetByCourseId(
      courseId,
      fallback: homeState.currentSkillset,
    );
    final course = homeState.skillsets.resolveCourseByCourseId(
      courseId,
      fallback: homeState.currentCourse,
      skillsetFallback: homeState.currentSkillset,
    );

    return CourseTrackingData(
      skillset: skillset,
      course: course,
    );
  }
}

class CourseLessonTrackingData extends CourseTrackingData {
  final LessonEntity lesson;

  const CourseLessonTrackingData({
    required super.skillset,
    required super.course,
    required this.lesson,
  });

  static CourseLessonTrackingData? fromLesson(BuildContext context, LessonEntity lesson) {
    if (lesson.id.isEmpty) return null;
    final trackingData = CourseTrackingData.fromCourseId(context, lesson.courseId);
    if (trackingData == null) return null;

    return CourseLessonTrackingData(
      skillset: trackingData.skillset,
      course: trackingData.course,
      lesson: lesson,
    );
  }
}

class LessonExplainTrackingData extends CourseLessonTrackingData {
  final String source;

  const LessonExplainTrackingData({
    required super.skillset,
    required super.course,
    required super.lesson,
    required this.source,
  });

  static LessonExplainTrackingData? fromLesson(
    BuildContext context,
    LessonEntity lesson, {
    required String source,
  }) {
    final trackingData = CourseLessonTrackingData.fromLesson(context, lesson);
    if (trackingData == null) return null;

    return LessonExplainTrackingData(
      skillset: trackingData.skillset,
      course: trackingData.course,
      lesson: trackingData.lesson,
      source: source,
    );
  }
}
