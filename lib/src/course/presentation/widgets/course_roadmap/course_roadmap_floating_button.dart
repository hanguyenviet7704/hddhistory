part of '../../../course.dart';

class CourseRoadmapFloatingButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String? label;

  const CourseRoadmapFloatingButton({
    super.key,
    required this.onPressed,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final hasProgress = context.select<CourseRoadmapCubit, bool>(
      (cubit) => cubit.state.roadmap.levels.any((level) => level.hasRoadmapProgress),
    );
    final labelText =
        label ??
        (hasProgress
            ? context.text.courseroadmap.continueLearningButton
            : context.text.courseroadmap.startLessonButton);
    return AppButton.primary(
      onPressed: onPressed,
      width: 160.w,
      height: 54.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      borderRadius: BorderRadius.circular(1000.r),
      child: AppText(
        labelText,
        style: AppStyle.textBold16.copyWith(
          color: AppCustomColor.textWhite,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
      ),
    );
  }
}
