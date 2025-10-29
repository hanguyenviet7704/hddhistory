part of '../../../../exercise.dart';

/// Mode Toggle Button (Keyboard/Microphone/Cancel)
/// A circular button that toggles between different input modes
class ModeToggleButton extends StatelessWidget {
  final String svgIcon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;
  final double padding;
  final double iconSize;

  const ModeToggleButton({
    super.key,
    required this.svgIcon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
    this.padding = 12,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(padding.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: SvgPicture.asset(
          svgIcon,
          height: iconSize.h,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        ),
      ),
    );
  }
}
