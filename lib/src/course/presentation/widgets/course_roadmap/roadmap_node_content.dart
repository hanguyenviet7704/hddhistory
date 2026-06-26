part of '../../../course.dart';

class RoadmapNodeContent extends StatelessWidget {
  final LessonEntity lesson;
  final bool isLocked;

  const RoadmapNodeContent({
    super.key,
    required this.lesson,
    required this.isLocked,
  });

  void _handleTap(BuildContext context) => RoadmapNodeActionHelper.startLessonAction(
    context,
    lesson,
    isLocked: isLocked,
  );

  @override
  Widget build(BuildContext context) {
    if (lesson.type == LessonType.roleplay || lesson.type == LessonType.output || lesson.type == LessonType.video) {
      return RoadmapLessonCard(
        lesson: lesson,
        isLocked: isLocked,
        onTap: () => _handleTap(context),
      );
    }

    if (lesson.type == LessonType.lesson) {
      if (lesson.keypoints.isEmpty) return const SizedBox.shrink();
      return LessonKeypointCard(
        lesson: lesson,
        isLocked: isLocked,
        onTap: () => _handleTap(context),
      );
    }

    return const SizedBox.shrink();
  }
}
