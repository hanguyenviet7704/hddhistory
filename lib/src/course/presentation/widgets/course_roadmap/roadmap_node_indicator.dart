part of '../../../course.dart';

class RoadmapNodeIndicator extends StatelessWidget {
  final LessonEntity lesson;

  const RoadmapNodeIndicator({
    super.key,
    required this.lesson,
  });

  Color _borderColor(bool isLastInProgress) => isLastInProgress ? AppCustomColor.borderBrand : AppCustomColor.neutral100;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CourseRoadmapCubit, CourseRoadmapState, bool>(
      selector: (state) {
        final lastInProgress = state.roadmap.lastInProgressLesson;
        if (lastInProgress == null) return false;
        return lastInProgress.isSameLesson(lesson);
      },
      builder: (context, isLastInProgress) {
        return Container(
          width: 54.w,
          height: 54.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _borderColor(isLastInProgress),
              width: 2.w,
            ),
          ),
          child: DCachedImage(
            url: lesson.roadmapIconUrl,
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }
}
