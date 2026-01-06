part of '../../../profile.dart';

class UserAchievementProgressBar extends StatelessWidget {
  const UserAchievementProgressBar({
    super.key,
    required this.progress,
    this.width,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
  });

  final double progress;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final double clampedProgress = progress.clamp(0.0, 1.0);
    final double barWidth = width ?? 67.w;
    final double barHeight = height ?? 6.h;

    return LinearPercentIndicator(
      width: barWidth,
      lineHeight: barHeight,
      percent: clampedProgress,
      padding: EdgeInsets.zero,
      animateFromLastPercent: true,
      backgroundColor: backgroundColor ?? AppCustomColor.borderSecondary,
      progressColor: foregroundColor ?? AppCustomColor.textPrimary,
      barRadius: Radius.circular(20.r),
    );
  }
}
