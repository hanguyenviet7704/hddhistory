part of '../widgets.dart';

class GuestLoginButton extends StatelessWidget {
  final VoidCallback onPressed;

  const GuestLoginButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SocialLoginButton(
      text: 'Continue as Guest',
      icon: const SizedBox.shrink(), // No icon for guest button
      backgroundColor: const Color(0xFFEBEAFD),
      textColor: const Color(0xFF110751),
      onPressed: onPressed,
      showArrow: true,
    );
  }
}
