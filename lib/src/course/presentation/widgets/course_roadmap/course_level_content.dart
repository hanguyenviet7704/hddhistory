part of '../../../course.dart';

class CourseLevelContent extends StatelessWidget {
  final RoadmapLevelEntity roadmapLevel;
  final int roadmapLevelIndex;
  final bool usingAppProgressLessons;
  const CourseLevelContent({
    super.key,
    required this.roadmapLevel,
    required this.roadmapLevelIndex,
    this.usingAppProgressLessons = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CourseRoadmapHeaderCard(roadmapLevel: roadmapLevel),
        20.verticalSpace,
        CourseRoadmapTimeline(
          roadmapLevelIndex: roadmapLevelIndex,
          lessons: roadmapLevel.appProgressLessons(usingAppProgressLessons),
          courseLevel: roadmapLevel.level,
        ),
      ],
    );
  }
}
