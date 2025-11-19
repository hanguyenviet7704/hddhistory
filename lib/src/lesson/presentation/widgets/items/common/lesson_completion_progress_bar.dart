part of '../../../../lesson.dart';

class LessonCompletionProgressBar extends StatelessWidget {
  const LessonCompletionProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    final double clampedProgress = 68.0 / 100.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120.w,
          height: 10.h,
          decoration: BoxDecoration(
            color: AppCustomColor.borderSecondary,
            borderRadius: BorderRadius.circular(24.r),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: clampedProgress,
            child: Container(
              decoration: BoxDecoration(
                color: AppCustomColor.brandPrimary,
                borderRadius: BorderRadius.circular(24.r),
              ),
            ),
          ),
        ),
        8.horizontalSpace,
        AppText(
          '${(clampedProgress * 100).round()}%',
          maxLines: 1,
          style: AppStyle.textBold12.copyWith(
            color: AppCustomColor.textPrimary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
