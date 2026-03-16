part of '../../../../lesson.dart';

class LessonExplainButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool hasExplanation;

  const LessonExplainButton({
    super.key,
    required this.onTap,
    this.hasExplanation = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasExplanation) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.5.h),
          decoration: BoxDecoration(
            color: AppCustomColor.borderDefault,
            borderRadius: BorderRadius.circular(1000.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                AppAsset.svg.app.icBookOpen,
                width: 20.w,
                height: 20.w,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF5F6F86),
                  BlendMode.srcIn,
                ),
              ),
              8.horizontalSpace,
              AppText(
                context.l10n.exercise.exerciseExplainButton,
                textAlign: TextAlign.center,
                style: AppStyle.text14.copyWith(
                  color: AppCustomColor.textTertiary,
                  fontWeight: FontWeight.w700,
                  height: 1.75,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
