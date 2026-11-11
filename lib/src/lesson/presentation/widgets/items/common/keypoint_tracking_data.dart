part of '../../../../lesson.dart';

class KeypointTrackingData {
  final CategoryEntity category;
  final CourseEntity course;
  final LessonEntity lesson;
  final KeypointEntity keypoint;

  const KeypointTrackingData({
    required this.category,
    required this.course,
    required this.lesson,
    required this.keypoint,
  });

  static KeypointTrackingData? fromLesson(
    BuildContext context, {
    required LessonEntity lesson,
    required KeypointEntity keypoint,
  }) {
    if (lesson.id.isEmpty || keypoint.id.isEmpty) return null;

    final courseTracking = CourseTrackingData.fromCourseId(context, lesson.courseId);
    if (courseTracking == null) return null;

    return KeypointTrackingData(
      category: courseTracking.category,
      course: courseTracking.course,
      lesson: lesson,
      keypoint: keypoint,
    );
  }

  static KeypointTrackingData? fromContext([BuildContext? _]) {
    final courseLessonState = AppDI.injector.get<CourseLessonCubit>().state;
    final lesson = courseLessonState.selectedLesson;
    if (lesson.id.isEmpty) return null;
    // A lesson the user generated belongs to no course, and the course/category
    // resolution below FALLS BACK to whatever the home screen last had — so
    // every keypoint event from an imported lesson would be filed against an
    // unrelated real course. No event is better than a wrong one; the import
    // feature reports its own.
    if (lesson.isImported) return null;

    final keypointId = courseLessonState.currentKeypointId;
    if (keypointId.isEmpty) return null;
    final keypoint = lesson.keypoints.firstWhere(
      (item) => item.id == keypointId,
      orElse: () => KeypointEntity(),
    );
    if (keypoint.id.isEmpty) return null;

    final homeState = AppDI.injector.get<HomeCubit>().state;
    final category = homeState.categories.resolveCategoryByCourseId(
      lesson.courseId,
      fallback: homeState.currentCategory,
    );
    final course = homeState.categories.resolveCourseByCourseId(
      lesson.courseId,
      fallback: homeState.currentCourse,
      categoryFallback: homeState.currentCategory,
    );

    return KeypointTrackingData(
      category: category,
      course: course,
      lesson: lesson,
      keypoint: keypoint,
    );
  }
}
