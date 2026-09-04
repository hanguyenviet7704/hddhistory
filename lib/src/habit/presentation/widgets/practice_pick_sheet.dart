part of '../../habit.dart';

/// What the user picked in the practice sheet.
/// `coach` is luồng 5 (design 2026-09-03): the same check-in, made in the chat.
enum PracticeChoice { journal, quiz, coach }

/// "How do you want to check in?" (design "5 · Habit" → practicepick).
///
/// The heading is why practice and check-in are the same write: picking a method
/// here IS filing the day's check-in, which is what both destinations do.
///
/// The quiz row only appears when the habit actually has a playable published
/// practice. Showing a disabled row instead would promise content that is not
/// there — most habits have none authored yet.
class PracticePickSheet extends StatelessWidget {
  final List<HabitPracticeEntity> practices;

  const PracticePickSheet({super.key, required this.practices});

  static Future<PracticeChoice?> show(
    BuildContext context, {
    required List<HabitPracticeEntity> practices,
  }) {
    return showModalBottomSheet<PracticeChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PracticePickSheet(practices: practices),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasQuiz = practices.any((practice) => practice.isPlayable);
    // Baked into the container's padding rather than a SafeArea wrapper, so the
    // white sheet stays flush to the bottom edge — same reason as
    // check_in_diary_sheet.dart.
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h + bottomInset),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppCustomColor.borderSecondary,
                borderRadius: BorderRadius.circular(99.r),
              ),
            ),
          ),
          20.verticalSpace,
          AppText(
            context.l10n.habit.practicePickTitle,
            style: AppStyle.textBold22.copyWith(color: AppCustomColor.textPrimary),
          ),
          6.verticalSpace,
          AppText(
            context.l10n.habit.practicePickSubtitle,
            style: AppStyle.text14.copyWith(color: AppCustomColor.textTertiary),
          ),
          22.verticalSpace,
          _option(
            context,
            icon: Icons.edit_outlined,
            iconBg: AppCustomColor.brandPrimary100,
            iconColor: AppCustomColor.brandPrimary,
            title: context.l10n.habit.practiceJournalTitle,
            subtitle: context.l10n.habit.practiceJournalSubtitle,
            onTap: () => Navigator.of(context).pop(PracticeChoice.journal),
          ),
          if (hasQuiz) ...[
            12.verticalSpace,
            _option(
              context,
              icon: Icons.help_outline_rounded,
              iconBg: AppCustomColor.successGreen.withValues(alpha: 0.12),
              iconColor: AppCustomColor.successGreen,
              title: context.l10n.habit.practiceQuizTitle,
              subtitle: context.l10n.habit.practiceQuizSubtitle,
              onTap: () => Navigator.of(context).pop(PracticeChoice.quiz),
            ),
          ],
          // Luồng 5 — the third row: write today or take the quiz WITH the
          // Coach, in the chat. Always offered; the sheet itself says so when
          // the Coach is switched off server-side.
          12.verticalSpace,
          _option(
            context,
            icon: Icons.chat_bubble_outline_rounded,
            iconBg: AppCustomColor.brandPrimary100,
            iconColor: AppCustomColor.brandPrimary,
            title: context.l10n.habit.practiceCoachTitle,
            subtitle: context.l10n.habit.practiceCoachSubtitle,
            onTap: () => Navigator.of(context).pop(PracticeChoice.coach),
          ),
        ],
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        AppHaptic.select();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppCustomColor.borderSecondary, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 46.w,
              height: 46.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(icon, size: 24.w, color: iconColor),
            ),
            14.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    title,
                    style: AppStyle.textBold16.copyWith(color: AppCustomColor.textPrimary),
                  ),
                  3.verticalSpace,
                  AppText(
                    subtitle,
                    // Design 13.5 — rounds to the app's 14, not 13.
                    style: AppStyle.text14.copyWith(color: AppCustomColor.textTertiary),
                  ),
                ],
              ),
            ),
            8.horizontalSpace,
            Icon(Icons.chevron_right_rounded, size: 22.w, color: AppCustomColor.textTertiary),
          ],
        ),
      ),
    );
  }
}
