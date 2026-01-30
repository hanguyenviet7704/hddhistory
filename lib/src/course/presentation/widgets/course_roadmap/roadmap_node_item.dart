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
    if (node.lessonsList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RoadmapSessionHeader(
          title: node.title,
          description: node.description,
        ),

        RoadmapNodeTimeline(
          items: node.lessonsList,
          levelLessons: levelLessons,
          lockedLessonStartIndex: lockedLessonStartIndex,
          courseLevel: courseLevel,
          roleplay: node.roleplay,
        ),
        32.verticalSpace,
      ],
    );
  }
}
