part of '../../../../lesson.dart';

class LessonCompletionPrimaryButton extends StatelessWidget {
  const LessonCompletionPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.margin = EdgeInsets.zero,
  });

  final String label;
  final VoidCallback? onPressed;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w).add(margin),
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            height: 54.h,
            decoration: BoxDecoration(
              color: AppCustomColor.brandPrimary,
              borderRadius: BorderRadius.circular(1000.r),
              boxShadow: [
                BoxShadow(
                  color: AppCustomColor.brandPrimary.op(0.25),
                  blurRadius: 20,
                  offset: Offset(0, 10.h),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: AppText(
              label,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: AppStyle.textBold16.copyWith(
                color: AppCustomColor.textWhite,
                height: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
