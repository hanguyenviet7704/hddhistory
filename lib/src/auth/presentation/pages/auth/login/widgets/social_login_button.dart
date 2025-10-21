part of '../../auth.dart';

class SocialLoginButton2 extends StatelessWidget {
  final String text;
  final String iconPath;
  final VoidCallback onPressed;

  const SocialLoginButton2({super.key, required this.text, required this.iconPath, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(color: const Color(0xFFEEF2F6), borderRadius: BorderRadius.circular(16.r)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(iconPath, width: 24.r, height: 24.r),
            8.horizontalSpace,
            AppText(text, style: AppStyle.text14.copyWith(fontWeight: FontWeight.w500, color: const Color(0xFF0D121C))),
          ],
        ),
      ),
    );
  }
}
