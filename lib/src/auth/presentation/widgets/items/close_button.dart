part of '../widgets.dart';

class CloseOverlayButton extends StatelessWidget {
  final VoidCallback onPressed;
  const CloseOverlayButton({super.key, required this.onPressed});


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColorLight.surface.op(0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          Icons.close_rounded,
          color: AppColorLight.surface,
        ),
      ),
    );
  }
}
