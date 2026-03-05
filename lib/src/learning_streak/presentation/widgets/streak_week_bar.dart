part of '../../learning_streak.dart';

class StreakWeekBar extends StatelessWidget {
  const StreakWeekBar({
    super.key,
    required this.weekStudy,
  });

  final List<bool> weekStudy;

  @override
  Widget build(BuildContext context) {
    final normalizedWeekStudy = weekStudy.length == 7 ? weekStudy : kLearningStreakEmptyWeekStudy;
    final activeIndexes = <int>[
      for (var index = 0; index < normalizedWeekStudy.length; index++)
        if (normalizedWeekStudy[index]) index,
    ];
    final latestActiveIndex = activeIndexes.isEmpty ? -1 : activeIndexes.last;
    final labels = [
      context.text.learningStreak.weekMon,
      context.text.learningStreak.weekTue,
      context.text.learningStreak.weekWed,
      context.text.learningStreak.weekThu,
      context.text.learningStreak.weekFri,
      context.text.learningStreak.weekSat,
      context.text.learningStreak.weekSun,
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final isActive = normalizedWeekStudy[index];
        final isLatestActive = isActive && index == latestActiveIndex;
        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24.r,
                height: 30.r,
                child: isLatestActive
                    ? SvgPicture.asset(
                        AppAsset.svg.app.icFlameCheck,
                        fit: BoxFit.contain,
                      )
                    : Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 24.r,
                          height: 24.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive ? AppCustomColor.streakActive : AppCustomColor.backgroundWhite,
                            border: Border.all(
                              color: isActive ? AppCustomColor.streakActive : AppCustomColor.borderDefault,
                              width: 2,
                            ),
                          ),
                          child: isActive
                              ? Icon(
                                  Icons.check,
                                  color: AppCustomColor.textWhite,
                                  size: 14.sp,
                                )
                              : null,
                        ),
                      ),
              ),
              SizedBox(height: 4.r),
              AppText(
                labels[index],
                maxLines: 1,
                textAlign: TextAlign.center,
                style: AppStyle.text12.copyWith(
                  color: isActive ? AppCustomColor.streakActive : AppCustomColor.streakTextMuted,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  height: 1.75,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
