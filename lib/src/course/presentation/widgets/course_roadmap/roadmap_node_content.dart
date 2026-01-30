part of '../../../course.dart';

class RoadmapNodeContent extends StatelessWidget {
  final LessonEntity lesson;
  final bool isLocked;
  final VoidCallback onRoleplayTap;
  final VoidCallback onKeypointTap;

  const RoadmapNodeContent({
    super.key,
    required this.lesson,
    required this.isLocked,
    required this.onRoleplayTap,
    required this.onKeypointTap,
  });

  @override
  Widget build(BuildContext context) {
    if (lesson.type == LessonType.roleplay) {
      return RoadmapRoleplayCard(
        lesson: lesson,
        isLocked: isLocked,
        onTap: onRoleplayTap,
      );
    }

    if (lesson.type == LessonType.lesson) {
      if (lesson.keypoints.isEmpty) return const SizedBox.shrink();
      return LessonKeypointCard(
        lesson: lesson,
        onTap: onKeypointTap,
      );
    }

    return const SizedBox.shrink();
  }
}
