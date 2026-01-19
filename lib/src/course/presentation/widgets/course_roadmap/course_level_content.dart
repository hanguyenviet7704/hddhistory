part of '../../../course.dart';

class CourseLevelContent extends StatelessWidget {
  final RoadmapLevelEntity roadmapLevel;
  final bool usingAppProgressLessons;
  final List<bool> lessonLocks;
  const CourseLevelContent({
    super.key,
    required this.roadmapLevel,
    this.usingAppProgressLessons = false,
    required this.lessonLocks,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CourseRoadmapHeaderCard(roadmapLevel: roadmapLevel),
        20.verticalSpace,
        CourseRoadmapTimeline(
          lessons: roadmapLevel.appProgressLessons(usingAppProgressLessons),
          courseLevel: roadmapLevel.level,
          lessonLocks: lessonLocks,
        ),
      ],
    );
  }
}
