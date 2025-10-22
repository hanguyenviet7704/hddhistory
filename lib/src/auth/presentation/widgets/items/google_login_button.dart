part of '../../../auth.dart';

class GoogleLoginButton extends StatelessWidget {
  final VoidCallback onPressed;

  const GoogleLoginButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SocialLoginButton(
      text: context.text.authGoogleLabel,
      icon: Image.asset(
        AppAsset.icons.common.logoGoogle.path,
        width: 18.w,
        height: 18.w,
      ),
      backgroundColor: Colors.white,
      textColor: const Color(0xFF0D121C),
      onPressed: onPressed,
    );
  }
}
