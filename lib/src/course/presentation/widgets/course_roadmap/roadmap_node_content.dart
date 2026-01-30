part of '../../../course.dart';

class RoadmapNodeContent extends StatelessWidget {
  final LessonEntity lesson;
  final bool isLocked;

  const RoadmapNodeContent({
    super.key,
    required this.lesson,
    required this.isLocked,
  });

  void _handleTap(BuildContext context) => context.read<CourseRoadmapCubit>().setCurrentLesson(lesson);
  
  @override
  Widget build(BuildContext context) {

    if (lesson.type == LessonType.roleplay) {
      return RoadmapRoleplayCard(
        lesson: lesson,
        isLocked: isLocked,
        onTap: () => _handleTap(context),
      );
    }

    if (lesson.type == LessonType.lesson) {
      if (lesson.keypoints.isEmpty) return const SizedBox.shrink();
      return LessonKeypointCard(
        lesson: lesson,
        onTap: () => _handleTap(context),
      );
    }

    return const SizedBox.shrink();
  }
}
