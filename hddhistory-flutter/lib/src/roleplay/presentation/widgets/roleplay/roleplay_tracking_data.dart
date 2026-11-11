part of '../../../roleplay.dart';

class RoleplayTrackingData {
  final CategoryEntity category;
  final CourseEntity course;
  final LessonEntity lesson;
  final LearningItemEntity learningItem;
  final RoleplayEntity roleplay;

  const RoleplayTrackingData({
    required this.category,
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
    final category = homeState.categories.resolveCategoryByCourseId(
      lesson.courseId,
      fallback: homeState.currentCategory,
    );
    final course = homeState.categories.resolveCourseByCourseId(
      lesson.courseId,
      fallback: homeState.currentCourse,
      categoryFallback: homeState.currentCategory,
    );

    return RoleplayTrackingData(
      category: category,
      course: course,
      lesson: lesson,
      learningItem: learningItem,
      roleplay: roleplay,
    );
  }
}
