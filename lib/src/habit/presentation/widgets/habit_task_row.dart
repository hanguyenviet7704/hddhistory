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
      onTap: () {
        AppHaptic.select();
        onOpenDetail();
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Row(
          children: [
            HabitDomainIcon(skillsetId: userHabit.habit?.skillsetId ?? '', size: 48),
            12.horizontalSpace,
            Expanded(
              child: AppText(
                userHabit.displayTitle,
                style: AppStyle.text14.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w600),
              ),
            ),
            Semantics(
              button: true,
              label: userHabit.displayTitle,
              value: done ? 'Done' : 'Not done',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  AppHaptic.select();
                  onCheckInTap();
                },
                // The check is a small 20px dot but is the row's primary action,
                // so make the whole trailing zone tappable (~56x52) — the dot
                // stays flush right, the empty space to its left also checks in.
                child: SizedBox(
                  width: 56.w,
                  height: 52.h,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 20.w,
                      height: 20.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // Unchecked: a faint white fill + a mid-slate ring
                        // (textTertiary, not the pale neutral300) so the target
                        // stays clearly visible on a translucent themed card
                        // instead of dissolving into it.
                        color: done ? AppCustomColor.streakActive : AppCustomColor.backgroundWhite.op(0.45),
                        border: done ? null : Border.all(color: AppCustomColor.textTertiary, width: 2),
                      ),
                      child: done ? Icon(Icons.check_rounded, size: 14.w, color: AppCustomColor.textWhite) : null,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
