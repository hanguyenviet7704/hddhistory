part of '../../../course.dart';

class CourseLevelContent extends StatelessWidget {
  final RoadmapLevelModel level;
  const CourseLevelContent({
    super.key,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CourseRoadmapHeaderCard(),
        // Roadmap timeline list
        CourseRoadmapTimeline(),
      ],
    );
  }
}
