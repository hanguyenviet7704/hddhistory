part of '../../habit.dart';

/// One habit on the Habit tab (design "5 · Habit" → Habit tab · Today).
///
/// The design gives every habit its OWN card, in a flat list — not a card per
/// category with the habits as checklist rows inside it. Four stacked parts,
/// separated by a hairline after the title:
///
///   icon + title            → opens the habit detail
///   ───────────────
///   seven weekday circles   → this week at a glance, read-only
///   state pill  ·  Details  → where it stands, and the way in
///
/// The week strip does not check in. Checking in is the practice flow — habit
/// detail → "Practice now" → journal or quiz — so a day is ticked by doing the
/// habit's practice, not by tapping a dot. That keeps one write path for a day's
/// row instead of two that can race on the same {habit, date}.
class HabitTrackerCard extends StatelessWidget {
  final UserHabitEntity userHabit;
  final VoidCallback onOpenDetail;

  const HabitTrackerCard({
    super.key,
    required this.userHabit,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: ThemedGlassCard(
        radius: 22,
        padding: EdgeInsets.all(16.w),
        shadow: [
          BoxShadow(
            color: AppCustomColor.textPrimary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title(context),
            12.verticalSpace,
            Container(height: 1, color: AppCustomColor.borderDefault),
            12.verticalSpace,
            _week(context),
            12.verticalSpace,
            _footer(context),
          ],
        ),
      ),
    );
  }

  Widget _title(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptic.select();
          onOpenDetail();
        },
        child: Row(
          children: [
            HabitDomainIcon(skillsetId: userHabit.habit?.skillsetId ?? '', imageUrl: userHabit.habit?.image ?? '', size: 44),
            12.horizontalSpace,
            Expanded(
              child: AppText(
                userHabit.displayTitle,
                maxLines: 3,
                // Design 16.5/500 — the title is the reading matter here, not a
                // heading, so it stays regular weight at a generous size.
                style: AppStyle.text16.copyWith(
                  fontSize: 16.5.sp,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                  color: AppCustomColor.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mon..Sun, evenly spread, 22px circles — filled with a tick for a done day.
  Widget _week(BuildContext context) {
    final days = userHabit.weekGrid.length == 7 ? userHabit.weekGrid : List<bool>.filled(7, false);
    final todayIndex = DateTime.now().weekday - 1;

    // Seven equal columns with the dot centred in each, matching the design's
    // `repeat(7,1fr); justify-items:center`. Not spaceBetween: that pins the
    // first and last dot to the card's padding edge, and today's larger tap
    // target then pushes its neighbours off the other cards' column positions.
    return Row(
      children: [
        for (int i = 0; i < 7; i++)
          Expanded(
            child: Center(child: _day(context, done: days[i], isToday: i == todayIndex)),
          ),
      ],
    );
  }

  Widget _day(BuildContext context, {required bool done, required bool isToday}) {
    return Semantics(
      label: done ? 'Done' : 'Not done',
      child: Container(
        width: 22.w,
        height: 22.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? AppCustomColor.streakActive : AppCustomColor.backgroundWhite.op(0.45),
          // Today keeps a brand ring purely as a "you are here" marker on the
          // strip — nothing here is tappable.
          border: done
              ? null
              : Border.all(
                  color: isToday ? AppCustomColor.brandPrimary : AppCustomColor.borderSecondary,
                  width: 2,
                ),
        ),
        child: done ? Icon(Icons.check_rounded, size: 13.w, color: AppCustomColor.textWhite) : null,
      ),
    );
  }

  Widget _footer(BuildContext context) {
    final done = userHabit.todayDone;
    return Row(
      children: [
        _pill(
          label: done ? context.l10n.habit.trackerStateDone : context.l10n.habit.trackerStateTodo,
          background: done ? AppCustomColor.kpCorrectSurface : AppCustomColor.habitStateTodoSurface,
          foreground: done ? AppCustomColor.kpCorrectText : AppCustomColor.habitStateTodoText,
          dot: done ? AppCustomColor.kpCorrectBorder : AppCustomColor.habitStateTodoDot,
        ),
        const Spacer(),
        Semantics(
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              AppHaptic.select();
              onOpenDetail();
            },
            child: Container(
              height: 26.h,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                color: AppCustomColor.brandPrimary50,
                borderRadius: BorderRadius.circular(999.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    context.l10n.habit.trackerDetails,
                    style: AppStyle.text12.copyWith(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppCustomColor.brandPrimary,
                    ),
                  ),
                  3.horizontalSpace,
                  Icon(Icons.chevron_right_rounded, size: 14.w, color: AppCustomColor.brandPrimary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pill({
    required String label,
    required Color background,
    required Color foreground,
    required Color dot,
  }) {
    return Container(
      height: 26.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5.w,
            height: 5.w,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          6.horizontalSpace,
          AppText(
            label,
            maxLines: 1,
            style: AppStyle.text12.copyWith(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
