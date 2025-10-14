part of '../../auth.dart';

class AuthButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const AuthButton({super.key, required this.onPressed, required this.text});

  @override
  Widget build(BuildContext context) {
    return GradientButton(
      text: text,
      style: AppStyle.textBold20.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      onPressed: onPressed,
      gradient: LinearGradient(colors: AppCustomColor.gradientButton, begin: Alignment.centerLeft, end: Alignment.centerRight, stops: const [0.2, 0.4, 0.55, 0.7, 0.97]),
    );
  }
}
