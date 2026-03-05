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
        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
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
                        Icons.local_fire_department_rounded,
                        color: AppCustomColor.textWhite,
                        size: 14.sp,
                      )
                    : null,
              ),
              AppText(
                labels[index],
                maxLines: 1,
                textAlign: TextAlign.center,
                style: AppStyle.text10.copyWith(
                  color: AppCustomColor.streakTextMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
