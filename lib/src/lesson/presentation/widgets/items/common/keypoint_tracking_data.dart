part of '../../../../lesson.dart';

class KeypointTrackingData {
  final SkillsetEntity skillset;
  final CourseEntity course;
  final LessonEntity lesson;
  final KeypointEntity keypoint;

  const KeypointTrackingData({
    required this.skillset,
    required this.course,
    required this.lesson,
    required this.keypoint,
  });

  static KeypointTrackingData? fromContext([BuildContext? _]) {
    final courseLessonState = AppDI.injector.get<CourseLessonCubit>().state;
    final lesson = courseLessonState.selectedLesson;
    if (lesson.id.isEmpty) return null;

    final keypointId = courseLessonState.currentKeypointId;
    if (keypointId.isEmpty) return null;
    final keypoint = lesson.keypoints.firstWhere(
      (item) => item.id == keypointId,
      orElse: () => KeypointEntity(),
    );
    if (keypoint.id.isEmpty) return null;

    final homeState = AppDI.injector.get<HomeCubit>().state;
    final skillset = homeState.skillsets.resolveSkillsetByCourseId(
      lesson.courseId,
      fallback: homeState.currentSkillset,
    );
    final course = homeState.skillsets.resolveCourseByCourseId(
      lesson.courseId,
      fallback: homeState.currentCourse,
      skillsetFallback: homeState.currentSkillset,
    );

    return KeypointTrackingData(
      skillset: skillset,
      course: course,
      lesson: lesson,
      keypoint: keypoint,
    );
  }
}
