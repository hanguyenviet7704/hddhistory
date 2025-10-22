part of '../../../auth.dart';

class AppleLoginButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AppleLoginButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SocialLoginButton(
      text: context.text.authAppleLabel,
      icon: Image.asset(
        AppAsset.icons.common.logoApple.path,
        width: 18.w,
        height: 18.w,
      ),
      backgroundColor: const Color(0xFF121C18),
      textColor: Colors.white,
      onPressed: onPressed,
    );
  }
}
