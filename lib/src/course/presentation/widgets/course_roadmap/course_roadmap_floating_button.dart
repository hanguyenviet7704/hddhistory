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
    // Return-refresher takes priority over the normal start/continue label
    // when a due warm-up with usable questions is available for this course.
    final hasWarmUpAvailable = context.select<WarmUpCubit, bool>((cubit) => cubit.state.hasWarmUpAvailable);
    final labelText = label ?? (hasWarmUpAvailable ? context.l10n.warmUp.floatingCtaLabel : (hasProgress ? context.l10n.courseroadmap.continueLearningButton : context.l10n.courseroadmap.startLessonButton));
    return Semantics(
      button: true,
      label: labelText,
      child: AppButton.primary(
        key: const Key('course-roadmap-floating-button'),
        onPressed: onPressed,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
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
      ),
    );
  }
}
