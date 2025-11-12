part of '../../../course.dart';

class CourseLevelContent extends StatelessWidget {
  final RoadmapLevelEntity level;
  const CourseLevelContent({
    super.key,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CourseRoadmapHeaderCard(level: level),
        20.verticalSpace,
        CourseRoadmapTimeline(lessons: level.lessonList),
      ],
    );
  }
}
