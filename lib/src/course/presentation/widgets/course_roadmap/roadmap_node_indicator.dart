part of '../../../course.dart';

class RoadmapNodeIndicator extends StatelessWidget {
  final LessonEntity lesson;

  const RoadmapNodeIndicator({
    super.key,
    required this.lesson,
  });

  Color _borderColor(bool selected) {
    if (selected) return AppCustomColor.borderBrand;

    return switch (lesson.roadmapProgress) {
      ProcessEnum.done || ProcessEnum.inProgress => AppCustomColor.brandPrimary50,
      ProcessEnum.notStarted => AppCustomColor.neutral100,
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CourseRoadmapCubit, CourseRoadmapState, bool>(
      selector: (state) => state.isLessonSelected(lesson),
      builder: (context, isSelected) {
        return Container(
          width: 54.w,
          height: 54.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _borderColor(isSelected),
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
