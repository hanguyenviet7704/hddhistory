part of '../widgets.dart';

class SocialLoginButton extends StatelessWidget {
  final String text;
  final Widget icon;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onPressed;
  final bool showArrow;

  const SocialLoginButton({
    super.key,
    required this.text,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54.h,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(1000.r),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(1000.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            SizedBox(width: 8.w),
            AppText(
              text,
              style: AppStyle.text16.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (showArrow) ...[
              SizedBox(width: 8.w),
              Icon(
                Icons.arrow_forward,
                color: textColor,
                size: 24.sp,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
