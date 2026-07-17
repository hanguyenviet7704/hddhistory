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
      margin: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
      width: double.infinity,
      height: 54.h,
      decoration: BoxDecoration(
        color: isEnabled ? activeBgColor : disabledBgColor,
        borderRadius: BorderRadius.circular(1000.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // Shared Continue button across every exercise body + theory/reading.
          // A light tap on advance so turning a reading page or moving to the
          // next question always "feels" pressed (custom InkWell — no DButton
          // haptic to inherit).
          onTap: isEnabled && onPressed != null
              ? () {
                  AppHaptic.select();
                  onPressed!();
                }
              : null,
          borderRadius: BorderRadius.circular(1000.r),
          child: Center(
            child: AppText(
              text,
              style: AppStyle.text16.copyWith(
                fontWeight: FontWeight.w600,
                color: isEnabled ? activeTextColor : disabledTextColor,
                height: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
