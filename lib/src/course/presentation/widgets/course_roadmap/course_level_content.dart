part of '../../../course.dart';

class CourseLevelContent extends StatelessWidget {
  final RoadmapLevelEntity level;
  final bool usingAppProgressLessons;
  const CourseLevelContent({
    super.key,
    required this.level,
    this.usingAppProgressLessons = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CourseRoadmapHeaderCard(level: level),
        20.verticalSpace,
        CourseRoadmapTimeline(lessons: level.appProgressLessons(usingAppProgressLessons)),
      ],
    );
  }
}
