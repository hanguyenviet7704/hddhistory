part of '../../../auth.dart';

class SocialLoginButton extends StatelessWidget {
  final String text;
  final Widget icon;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onPressed;
  final bool showArrow;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.text,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
    this.showArrow = false,
    this.isLoading = false,
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
        onPressed: isLoading
            ? null
            : () {
                AppHaptic.select();
                onPressed();
              },
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(1000.r),
          ),
        ),
        child: isLoading
            ? SizedBox(width: 20.w, height: 20.w, child: CircularProgressIndicator(strokeWidth: 2, color: textColor))
            : Row(
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
