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
    // Today's slot (Mon=0 … Sun=6). Before it's studied, today shows a
    // highlighted brand-bordered empty ring — the design's "do this today" cue —
    // instead of the muted grey used for future days.
    final todayIndex = DateTime.now().weekday - 1;
    final labels = [
      context.l10n.learningStreak.weekMon,
      context.l10n.learningStreak.weekTue,
      context.l10n.learningStreak.weekWed,
      context.l10n.learningStreak.weekThu,
      context.l10n.learningStreak.weekFri,
      context.l10n.learningStreak.weekSat,
      context.l10n.learningStreak.weekSun,
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final isActive = normalizedWeekStudy[index];
        // Today, not yet studied → highlighted ring (brand border, no fill).
        final isTodayPending = index == todayIndex && !isActive;
        final isHighlighted = isActive || isTodayPending;
        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24.r,
                height: 24.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? AppCustomColor.streakActive : AppCustomColor.backgroundWhite,
                  border: Border.all(
                    color: isHighlighted ? AppCustomColor.streakActive : AppCustomColor.borderDefault,
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
              SizedBox(height: 4.r),
              AppText(
                labels[index],
                maxLines: 1,
                textAlign: TextAlign.center,
                style: AppStyle.text12.copyWith(
                  color: isHighlighted ? AppCustomColor.streakActive : AppCustomColor.streakTextMuted,
                  fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
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
