part of '../../../course.dart';

class CourseTrackingData {
  final CategoryEntity category;
  final CourseEntity course;

  const CourseTrackingData({
    required this.category,
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
    final category = homeState.categories.resolveCategoryByCourseId(
      courseId,
      fallback: homeState.currentCategory,
    );
    final course = homeState.categories.resolveCourseByCourseId(
      courseId,
      fallback: homeState.currentCourse,
      categoryFallback: homeState.currentCategory,
    );

    return CourseTrackingData(
      category: category,
      course: course,
    );
  }

  static CourseTrackingData fromTrackingValues({
    required String categoryId,
    required String categoryName,
    required String courseId,
    required String courseName,
  }) {
    final category = CategoryEntity(
      id: categoryId,
      title: BaseMultiLanguage(en: categoryName),
    );
    final course = CourseEntity(
      id: courseId,
      title: BaseMultiLanguage(en: courseName),
      categoryId: categoryId,
      category: category,
    );

    return CourseTrackingData(
      category: category,
      course: course,
    );
  }
}

class CourseLessonTrackingData extends CourseTrackingData {
  final LessonEntity lesson;

  const CourseLessonTrackingData({
    required super.category,
    required super.course,
    required this.lesson,
  });

  static CourseLessonTrackingData? fromLesson(BuildContext context, LessonEntity lesson) {
    if (lesson.id.isEmpty) return null;
    final trackingData = CourseTrackingData.fromCourseId(context, lesson.courseId);
    if (trackingData == null) return null;

    return CourseLessonTrackingData(
      category: trackingData.category,
      course: trackingData.course,
      lesson: lesson,
    );
  }
}

class LessonExplainTrackingData extends CourseLessonTrackingData {
  final String source;

  const LessonExplainTrackingData({
    required super.category,
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
      category: trackingData.category,
      course: trackingData.course,
      lesson: trackingData.lesson,
      source: source,
    );
  }
}
