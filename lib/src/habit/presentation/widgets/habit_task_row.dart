part of '../../habit.dart';

/// Today's checklist row (Task view). Two tap zones per PRD §9.3/§9.4:
/// tapping the row opens Habit detail; tapping the check circle opens the
/// check-in + diary sheet.
class HabitTaskRow extends StatelessWidget {
  final UserHabitEntity userHabit;
  final VoidCallback onCheckInTap;
  final VoidCallback onOpenDetail;

  const HabitTaskRow({
    super.key,
    required this.userHabit,
    required this.onCheckInTap,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final done = userHabit.todayDone;
    return InkWell(
      onTap: onOpenDetail,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            HabitDomainIcon(skillsetId: userHabit.habit?.skillsetId ?? '', fallbackEmoji: userHabit.displayIcon, size: 48),
            12.horizontalSpace,
            Expanded(
              child: AppText(
                userHabit.displayTitle,
                style: AppStyle.text14.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w600),
              ),
            ),
            12.horizontalSpace,
            Semantics(
              button: true,
              label: userHabit.displayTitle,
              value: done ? 'Done' : 'Not done',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onCheckInTap,
                child: Container(
                  width: 20.w,
                  height: 20.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? AppCustomColor.streakActive : Colors.transparent,
                    border: done ? null : Border.all(color: AppCustomColor.neutral300, width: 2),
                  ),
                  child: done ? Icon(Icons.check, size: 12.w, color: AppCustomColor.textWhite) : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
