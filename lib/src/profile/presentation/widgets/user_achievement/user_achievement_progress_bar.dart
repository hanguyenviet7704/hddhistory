part of '../../../profile.dart';

class UserAchievementProgressBar extends StatelessWidget {
  const UserAchievementProgressBar({
    super.key,
    required this.progress,
  });

  final double progress;

  @override
  Widget build(BuildContext context) {
    final double clampedProgress = progress.clamp(0.0, 1.0);
    final double width = 67.w;
    final double height = 6.h;

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppCustomColor.borderSecondary,
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: clampedProgress,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppCustomColor.textPrimary,
                borderRadius: BorderRadius.circular(18.r),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
