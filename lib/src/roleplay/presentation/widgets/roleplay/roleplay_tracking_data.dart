part of '../../../roleplay.dart';

class RoleplayTrackingData {
  final SkillsetEntity skillset;
  final CourseEntity course;
  final LessonEntity lesson;
  final LearningItemEntity learningItem;
  final RoleplayEntity roleplay;

  const RoleplayTrackingData({
    required this.skillset,
    required this.course,
    required this.lesson,
    required this.learningItem,
    required this.roleplay,
  });

  static RoleplayTrackingData? fromContext([BuildContext? _]) {
    final roleplayState = AppDI.injector.get<RoleplayCubit>().state;
    final lesson = roleplayState.currentLesson;
    if (lesson.id.isEmpty) return null;
    final learningItem = roleplayState.currentLearningItem;
    final roleplay = roleplayState.currentRoleplay;

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

    return RoleplayTrackingData(
      skillset: skillset,
      course: course,
      lesson: lesson,
      learningItem: learningItem,
      roleplay: roleplay,
    );
  }
}
