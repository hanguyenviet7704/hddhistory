part of '../../../../exercise.dart';

/// Mode Toggle Button (Keyboard/Microphone/Cancel)
/// A circular button that toggles between different input modes
class ModeToggleButton extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final double? size;
  final VoidCallback onTap;

  const ModeToggleButton({
    super.key,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = size ?? 48.w;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(1000.r),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 24.w,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
