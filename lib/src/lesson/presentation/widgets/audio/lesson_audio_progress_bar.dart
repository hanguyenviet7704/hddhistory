part of '../../../lesson.dart';

class LessonAudioProgressBar extends StatelessWidget {
  const LessonAudioProgressBar({
    super.key,
    required this.progress,
  });

  final double progress;

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    return SizedBox(
      height: 16.h,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final knobCenter = constraints.maxWidth * clampedProgress;
          final knobLeft = knobCenter.clamp(8.w, constraints.maxWidth - 8.w) - 8.w;

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 8.h,
                decoration: BoxDecoration(
                  color: AppCustomColor.borderSecondary,
                  borderRadius: BorderRadius.circular(30.r),
                ),
              ),
              FractionallySizedBox(
                widthFactor: clampedProgress,
                child: Container(
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: AppCustomColor.brandPrimary,
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
              ),
              Positioned(
                left: knobLeft,
                child: Container(
                  width: 16.r,
                  height: 16.r,
                  decoration: BoxDecoration(
                    color: AppCustomColor.backgroundWhite,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppCustomColor.brandPrimary,
                      width: 4.w,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
