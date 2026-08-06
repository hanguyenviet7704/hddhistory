part of '../../habit.dart';

/// Full habit diary (design "5 · Habit" → FULL DIARY POPUP).
///
/// The detail sheet's diary card only previews the newest few entries; this is
/// where the rest live. Read-only on purpose — the design offers no edit or
/// delete here, and a check-in is the streak's evidence, so it must not be
/// removable by a stray tap in a scrolling list.
///
/// Presented over the detail sheet rather than replacing it, matching the
/// design's stacked overlay: closing this returns to the habit the entries
/// belong to instead of dumping the user back on the tracker.
class HabitDiaryAllSheet extends StatelessWidget {
  /// Newest first, already filtered to done check-ins by the caller.
  final List<HabitCheckinEntity> entries;

  const HabitDiaryAllSheet({super.key, required this.entries});

  static Future<void> show(
    BuildContext context, {
    required List<HabitCheckinEntity> entries,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      // Design leaves a 120px gap to the top edge so the sheet reads as stacked
      // over the detail sheet, not as a new screen.
      constraints: BoxConstraints(maxHeight: 1.sh - 120.h),
      builder: (_) => HabitDiaryAllSheet(entries: entries),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(22.w, 22.h, 22.w, 14.h),
            child: Column(
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
                18.verticalSpace,
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            context.l10n.habit.detailDiaryTitle,
                            style: AppStyle.textBold22.copyWith(color: AppCustomColor.textPrimary),
                          ),
                          3.verticalSpace,
                          AppText(
                            context.l10n.habit.detailDiaryCount(count: '${entries.length}'),
                            style: AppStyle.text14.copyWith(color: AppCustomColor.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    12.horizontalSpace,
                    Semantics(
                      button: true,
                      label: context.l10n.common.close,
                      child: GestureDetector(
                        onTap: () {
                          AppHaptic.select();
                          Navigator.of(context).pop();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 34.w,
                          height: 34.w,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppCustomColor.backgroundGray,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close, size: 22.w, color: AppCustomColor.textTertiary),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(22.w, 0, 22.w, 30.h + bottomInset),
              itemCount: entries.length,
              itemBuilder: (context, index) => HabitDiaryRow(
                entry: entries[index],
                // The design separates every row here with a top border,
                // including the first — the header sits directly above it.
                showTopBorder: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One `date | mood | text` diary line.
///
/// Shared by the detail sheet's preview card and [HabitDiaryAllSheet] so the two
/// cannot drift apart — the design draws the same row in both, differing only in
/// the separator.
class HabitDiaryRow extends StatelessWidget {
  final HabitCheckinEntity entry;
  final bool showTopBorder;

  const HabitDiaryRow({super.key, required this.entry, this.showTopBorder = false});

  @override
  Widget build(BuildContext context) {
    // A check-in with no note still logs as a diary entry, shown as a muted
    // "Checked in" so it reads as a system label, not user-written content.
    final note = entry.note?.trim() ?? '';
    final hasNote = note.isNotEmpty;
    final mood = JournalMood.fromValue(entry.mood);

    // The design draws this row slightly larger in the full sheet than in the
    // detail card's preview (14px padding and a 52px date column against 11px
    // and 50px), and only the full sheet gets the hairline. [showTopBorder]
    // already distinguishes the two, so it selects both.
    final isFullSheet = showTopBorder;

    return Container(
      padding: EdgeInsets.symmetric(vertical: isFullSheet ? 14.h : 11.h),
      decoration: showTopBorder
          ? BoxDecoration(
              border: Border(top: BorderSide(color: AppCustomColor.borderDefault)),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wider than the design's 50/52: the design's mock dates are short
          // month names ("Jan 6"), while this renders `d/M/yy`, and at 52 a
          // two-digit day AND month wrapped onto a second line ("31/7/2" then
          // "6"). Kept to one line so every row stays the same height.
          SizedBox(
            width: isFullSheet ? 62.w : 58.w,
            child: AppText(
              entry.date.parseString('d/M/yy'),
              maxLines: 1,
              // Brand-tinted, not muted grey: the design uses the date as the
              // row's anchor, and it has to stay readable against the note text
              // that dominates the row.
              style: (isFullSheet ? AppStyle.text14 : AppStyle.text13).copyWith(
                color: AppCustomColor.brandPrimary300,
                fontWeight: isFullSheet ? FontWeight.w600 : FontWeight.w700,
              ),
            ),
          ),
          // Fixed width even when empty so note text stays aligned down the
          // list — journal days and tap-only days share this column.
          SizedBox(
            width: 26.w,
            child: AppText(
              mood?.emoji ?? '',
              textAlign: TextAlign.center,
              style: AppStyle.text18,
            ),
          ),
          6.horizontalSpace,
          Expanded(
            child: AppText(
              hasNote ? note : context.l10n.habit.detailDiaryCheckedIn,
              maxLines: 6,
              // Design is 15.5px; the app's scale has no 15, and 16 is the
              // nearest token — the scale wins over a half-pixel.
              style: AppStyle.text16.copyWith(
                fontWeight: FontWeight.w500,
                height: isFullSheet ? 1.4 : 1.45,
                color: hasNote ? AppCustomColor.textPrimary : AppCustomColor.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
