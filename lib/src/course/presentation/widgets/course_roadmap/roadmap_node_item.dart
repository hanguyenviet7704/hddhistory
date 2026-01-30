part of '../../../course.dart';

class RoadmapNodeItem extends StatelessWidget {
  final RoadmapNodeEntity node;
  final CourseLevel courseLevel;
  final int lockedLessonStartIndex;
  final List<LessonEntity> levelLessons;

  const RoadmapNodeItem({
    super.key,
    required this.node,
    required this.courseLevel,
    required this.lockedLessonStartIndex,
    required this.levelLessons,
  });

  @override
  Widget build(BuildContext context) {
    final items = node.timelineItems(levelLessons);
    if (items.isEmpty) return const SizedBox.shrink();
    final resolvedRoleplay = node.resolveRoleplay(levelLessons);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RoadmapSessionHeader(
          title: node.title,
          description: node.description,
        ),

        _RoadmapNodeTimeline(
          items: items,
          levelLessons: levelLessons,
          lockedLessonStartIndex: lockedLessonStartIndex,
          courseLevel: courseLevel,
          roleplay: resolvedRoleplay,
        ),
        32.verticalSpace,
      ],
    );
  }
}
