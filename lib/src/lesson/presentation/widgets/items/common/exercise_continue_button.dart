part of '../../../../lesson.dart';

class ExerciseContinueButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isEnabled;
  final Color? backgroundColor;
  final Color? disabledBackgroundColor;
  final Color? textColor;
  final Color? disabledTextColor;

  const ExerciseContinueButton({
    super.key,
    required this.onPressed,
    this.text = 'Continue',
    this.isEnabled = true,
    this.backgroundColor,
    this.disabledBackgroundColor,
    this.textColor,
    this.disabledTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeBgColor = backgroundColor ?? const Color(0xFF554FF0);
    final disabledBgColor = disabledBackgroundColor ?? const Color(0xFFE3E8EF);
    final activeTextColor = textColor ?? Colors.white;
    final disabledTextColor = this.disabledTextColor ?? const Color(0xFF7F8EA4);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: AppButton.primary(
        onPressed: isEnabled ? onPressed : null,
        fullWidthBtn: true,
        height: 54.h,
        disabled: !isEnabled,
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100.r)),
          color: isEnabled ? activeBgColor : disabledBgColor,
        ),
        child: AppText(
          text,
          style: AppStyle.textBold16.copyWith(
            color: isEnabled ? activeTextColor : disabledTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
