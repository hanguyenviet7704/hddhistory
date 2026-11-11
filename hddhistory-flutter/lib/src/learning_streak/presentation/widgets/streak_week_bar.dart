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
        final isToday = index == todayIndex;
        // Today is always highlighted (brand colour + ring), so is any past
        // studied day.
        final isHighlighted = isActive || isToday;

        // Inner marker: studied → filled brand circle + check; otherwise an
        // empty circle whose border is brand for today (the design's ring) and
        // grey for other unstudied days.
        final Widget circle = Container(
          width: 28.r,
          height: 28.r,
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
                  size: 16.sp,
                )
              : null,
        );

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fixed-height slot so today's outer ring never shifts the labels
              // out of line with the other days.
              SizedBox(
                height: 36.r,
                child: Center(
                  // Today ALWAYS wears an outer ring so the current day stays
                  // marked even once it's studied. A not-yet-studied today is
                  // already an empty brand ring, so it needs no second ring.
                  child: isToday && isActive
                      ? Container(
                          padding: EdgeInsets.all(2.r),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppCustomColor.streakActive, width: 1.5),
                          ),
                          child: circle,
                        )
                      : circle,
                ),
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
