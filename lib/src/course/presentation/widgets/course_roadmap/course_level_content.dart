part of '../../../course.dart';

class CourseLevelContent extends StatelessWidget {
  final RoadmapLevelEntity roadmapLevel;
  final bool usingAppProgressLessons;
  final int lockedLessonStartIndex;
  const CourseLevelContent({
    super.key,
    required this.roadmapLevel,
    this.usingAppProgressLessons = false,
    required this.lockedLessonStartIndex,
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
          lockedLessonStartIndex: lockedLessonStartIndex,
        ),
      ],
    );
  }
}
