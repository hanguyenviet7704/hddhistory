part of '../../../../lesson.dart';

class LessonExplainButton extends StatelessWidget {
  final VoidCallback onTap;

  const LessonExplainButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              AppAsset.svg.app.icBookOpen,
              width: 20.w,
              height: 20.w,
            ),
            8.horizontalSpace,
            AppText(
              context.text.exercise.exerciseExplainButton,
              style: AppStyle.text14.copyWith(
                color: AppCustomColor.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
