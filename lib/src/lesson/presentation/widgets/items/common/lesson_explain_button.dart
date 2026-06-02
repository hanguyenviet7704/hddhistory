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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: 40.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppCustomColor.brandPrimary50,
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
                AppCustomColor.brandPrimary,
                BlendMode.srcIn,
              ),
            ),
            8.horizontalSpace,
            AppText(
              context.l10n.exercise.exerciseExplainButton,
              textAlign: TextAlign.center,
              style: AppStyle.text14.copyWith(
                color: AppCustomColor.brandPrimary,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
