part of '../../../course.dart';

class CourseLevelContent extends StatelessWidget {
  final RoadmapLevelEntity roadmapLevel;
  const CourseLevelContent({
    super.key,
    required this.roadmapLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CourseRoadmapHeaderCard(roadmapLevel: roadmapLevel),
        16.verticalSpace,
        ...roadmapLevel.nodes.map(
          (node) => RoadmapNodeItem(
            node: node,
          ),
        ),

        // CourseRoadmapTimeline(
        //   lessons: roadmapLevel.appProgressLessons(usingAppProgressLessons),
        //   courseLevel: roadmapLevel.level,
        //   lockedLessonStartIndex: lockedLessonStartIndex,
        // ),
      ],
    );
  }
}
