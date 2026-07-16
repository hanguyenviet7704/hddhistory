part of '../../../auth.dart';

class AppleLoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const AppleLoginButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SocialLoginButton(
      text: context.l10n.auth.authAppleLabel,
      icon: Image.asset(
        AppAsset.icons.common.logoApple.path,
        width: 18.w,
        height: 18.w,
      ),
      backgroundColor: const Color(0xFF121C18),
      textColor: Colors.white,
      onPressed: onPressed,
      isLoading: isLoading,
    );
  }
}
