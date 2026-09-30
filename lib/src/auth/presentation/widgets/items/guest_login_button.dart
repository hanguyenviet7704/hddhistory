part of '../../../auth.dart';

class GuestLoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const GuestLoginButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SocialLoginButton(
      text: context.l10n.auth.authGuestOption,
      icon: const SizedBox.shrink(), // No icon for guest button
      backgroundColor: const Color(0xFFFDF8EA),
      textColor: const Color(0xFF513C07),
      onPressed: onPressed,
      showArrow: true,
      isLoading: isLoading,
    );
  }
}
