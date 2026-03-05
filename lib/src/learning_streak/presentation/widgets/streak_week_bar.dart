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
                width: 24.w,
                height: isLatestActive ? 30.h : 24.h,
                child: isLatestActive
                    ? SvgPicture.asset(
                        AppAsset.svg.app.icFlameCheck,
                        fit: BoxFit.contain,
                      )
                    : Container(
                        width: 24.w,
                        height: 24.w,
                        margin: EdgeInsets.only(bottom: 6.h),
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
              6.verticalSpace,
              AppText(
                labels[index],
                maxLines: 1,
                textAlign: TextAlign.center,
                style: AppStyle.text10.copyWith(
                  color: isActive ? AppCustomColor.streakActive : AppCustomColor.streakTextMuted,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
