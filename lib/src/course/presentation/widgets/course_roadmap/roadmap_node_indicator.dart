part of '../../../course.dart';

class RoadmapNodeIndicator extends StatelessWidget {
  final LessonEntity lesson;

  const RoadmapNodeIndicator({
    super.key,
    required this.lesson,
  });

  Color get _borderColor {
    switch (lesson.roadmapProgress) {
      case ProcessEnum.done || ProcessEnum.inProgress:
        return AppCustomColor.borderBrand;
      case ProcessEnum.notStarted:
        return AppCustomColor.neutral100;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = context.select<CourseRoadmapCubit, bool>((cubit) => cubit.state.isLessonSelected(lesson));
    final borderColor = isSelected ? AppCustomColor.brandPrimary : _borderColor;
    final borderWidth = isSelected ? 3.w : 2.w;
    return Container(
      width: 54.w,
      height: 54.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: DCachedImage(
        url: lesson.roadmapIconUrl,
        fit: BoxFit.contain,
      ),
    );
  }
}
