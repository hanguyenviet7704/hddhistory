part of '../../../course.dart';

class CourseTrackingData {
  final SkillsetEntity skillset;
  final CourseEntity course;

  const CourseTrackingData({
    required this.skillset,
    required this.course,
  });

  static CourseTrackingData? fromCourseId(BuildContext context, String courseId) {
    return fromHomeState(context.read<HomeCubit>().state, courseId);
  }

  /// Context-free variant, for callers that cannot rely on a `HomeCubit` being
  /// above them in the widget tree — the lesson flow's routes do not provide
  /// one, so `fromCourseId` throws there (`HomeCubit` is a `@lazySingleton`, so
  /// reading it from `AppDI.injector` yields the very same instance the other
  /// routes wrap).
  static CourseTrackingData? fromHomeState(HomeState homeState, String courseId) {
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

  static CourseTrackingData fromTrackingValues({
    required String skillsetId,
    required String skillsetName,
    required String courseId,
    required String courseName,
  }) {
    final skillset = SkillsetEntity(
      id: skillsetId,
      title: BaseMultiLanguage(en: skillsetName),
    );
    final course = CourseEntity(
      id: courseId,
      title: BaseMultiLanguage(en: courseName),
      skillsetId: skillsetId,
      skillset: skillset,
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
