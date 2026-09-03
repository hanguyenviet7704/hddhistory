part of '../../study_journal.dart';

/// The four shades behind the "Ít → Nhiều" legend, lightest first.
///
/// Tints of the brand indigo rather than a separate hue: the square is a
/// quantity of the same thing (study), and a rainbow would read as four
/// different kinds of day.
const List<Color> _kLevelColors = [
  Color(0xFFE7E5FC),
  Color(0xFFC0BAF7),
  Color(0xFF8B83EF),
  Color(0xFF554FF0),
];

const Color _kEmptyPastColor = Color(0xFFECECF0);
const Color _kEmptyPastInk = Color(0xFFA6A8B4);
const Color _kFutureInk = Color(0xFFC5C1DC);
const Color _kFutureBorder = Color(0xFFF1EFF8);
const Color _kStudyBorder = Color(0xFFECEAF7);
const Color _kDividerColor = Color(0xFFEFEDF8);
const Color _kNavButtonBg = Color(0xFFF1F0FA);

/// Weekday header + hint ink. Darker than the design's #B4BCC9: that value was
/// picked against solid white, and on a translucent card over a photo it drops
/// below readable.
const Color _kWeekdayInk = Color(0xFF8A94A6);

/// Local twins of the Profile page's own card shadow and text style — those
/// are private to that library, and re-declaring the two values is cheaper
/// than widening their API for one more caller.
List<BoxShadow> get _journalCardShadow => [
  BoxShadow(color: const Color(0x0D252525), offset: Offset(0, 6.h), blurRadius: 18.r),
];

TextStyle _journalText(
  double size,
  FontWeight weight, {
  Color color = AppCustomColor.textPrimary,
}) => TextStyle(fontFamily: AppFont.mulish, fontSize: size.sp, fontWeight: weight, color: color);

/// Profile's "Nhật ký học tập": a month of squares, one per day, shaded by how
/// many keypoints were finished that day (design `6 · Profile`).
///
/// Swipe left/right or use the arrows to change month; tap a past square to
/// open that day's history.
class StudyJournalCalendar extends StatefulWidget {
  const StudyJournalCalendar({super.key});

  @override
  State<StudyJournalCalendar> createState() => _StudyJournalCalendarState();
}

class _StudyJournalCalendarState extends State<StudyJournalCalendar> {
  late final StudyJournalCubit _cubit = AppDI.injector.get<StudyJournalCubit>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_cubit.ensureLoaded());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudyJournalCubit, StudyJournalState>(
      bloc: _cubit,
      builder: (context, state) {
        // Translucent white over a custom study background, same as every other
        // card on this screen — the earlier readability problem was the INK,
        // not the panel: the month title was flipping to light ({@template} see
        // below) and the two greys below were pitched for a white page.
        return ThemedGlassCard(
          key: const Key('profile-study-journal'),
          padding: EdgeInsets.all(14.w),
          radius: 20,
          shadow: _journalCardShadow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MonthHeader(state: state, cubit: _cubit),
              16.verticalSpace,
              // The whole grid is the swipe target, not just a filled square —
              // an empty month must still be swipeable away from.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragEnd: (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  if (velocity > 0) unawaited(_cubit.goPrevious());
                  if (velocity < 0) unawaited(_cubit.goNext());
                },
                child: Column(
                  children: [
                    const _WeekdayRow(),
                    8.verticalSpace,
                    _MonthGrid(state: state, onTapDay: _openDay),
                  ],
                ),
              ),
              12.verticalSpace,
              Container(height: 1, color: _kDividerColor),
              9.verticalSpace,
              const _Legend(),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openDay(DateTime day) async {
    await StudyJournalDaySheet.show(context, day: day, cubit: _cubit);
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.state, required this.cubit});

  final StudyJournalState state;
  final StudyJournalCubit cubit;

  @override
  Widget build(BuildContext context) {
    final month = state.visibleMonth ?? DateTime.now();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _NavButton(
          icon: Icons.chevron_left_rounded,
          enabled: state.canGoPrevious,
          onTap: cubit.goPrevious,
          semanticsLabel: context.l10n.studyJournal.previousMonth,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              context.l10n.studyJournal.monthName(month: month.month),
              // Plain ink, NOT studyThemeOnBg: that helper flips text to light
              // for content sitting directly ON a dark background, and this
              // sits inside a solid white card — it came out nearly invisible.
              style: _journalText(16, FontWeight.w700),
            ),
            4.horizontalSpace,
            AppText(
              '${month.year}',
              style: _journalText(16, FontWeight.w600, color: AppCustomColor.textSecondary),
            ),
          ],
        ),
        _NavButton(
          icon: Icons.chevron_right_rounded,
          enabled: state.canGoNext,
          onTap: cubit.goNext,
          semanticsLabel: context.l10n.studyJournal.nextMonth,
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.semanticsLabel,
  });

  final IconData icon;
  final bool enabled;
  final Future<void> Function() onTap;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticsLabel,
      child: Opacity(
        // Dimmed rather than removed: the arrows are what tell the learner the
        // calendar pages at all, and a month with no earlier data would
        // otherwise look like a screen with no navigation.
        opacity: enabled ? 1 : 0.35,
        child: GestureDetector(
          onTap: enabled ? () => unawaited(onTap()) : null,
          child: Container(
            width: 32.w,
            height: 32.w,
            decoration: const BoxDecoration(color: _kNavButtonBg, shape: BoxShape.circle),
            child: Icon(icon, size: 20.sp, color: AppCustomColor.brandPrimary),
          ),
        ),
      ),
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow();

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n.studyJournal.weekdays.split(',');

    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: AppText(
              label.trim(),
              textAlign: TextAlign.center,
              style: _journalText(11, FontWeight.w700, color: _kWeekdayInk),
            ),
          ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.state, required this.onTapDay});

  final StudyJournalState state;
  final ValueChanged<DateTime> onTapDay;

  @override
  Widget build(BuildContext context) {
    final month = state.visibleMonth ?? DateTime.now();
    final data = state.currentMonth;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Monday-first, matching the streak week bar above it on this same screen:
    // two week strips that disagreed on where a week starts would be worse than
    // either convention on its own.
    final firstOfMonth = DateTime(month.year, month.month);
    final leadingBlanks = firstOfMonth.weekday - DateTime.monday;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final cellCount = leadingBlanks + daysInMonth;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: cellCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: DateTime.daysPerWeek,
        mainAxisSpacing: 6.w,
        crossAxisSpacing: 6.w,
      ),
      itemBuilder: (context, index) {
        if (index < leadingBlanks) return const SizedBox.shrink();

        final dayNumber = index - leadingBlanks + 1;
        final date = DateTime(month.year, month.month, dayNumber);
        final entry = data?.days[formatStudyJournalDate(date)];

        return _DayCell(
          date: date,
          day: dayNumber,
          level: entry?.level ?? 0,
          keypoints: entry?.keypoints ?? 0,
          isToday: date == todayDate,
          isFuture: date.isAfter(todayDate),
          onTap: onTapDay,
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.day,
    required this.level,
    required this.keypoints,
    required this.isToday,
    required this.isFuture,
    required this.onTap,
  });

  final DateTime date;
  final int day;
  final int level;
  final int keypoints;
  final bool isToday;
  final bool isFuture;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final hasStudy = level > 0;
    final background = switch (true) {
      _ when hasStudy => _kLevelColors[(level - 1).clamp(0, _kLevelColors.length - 1)],
      _ when isFuture => Colors.transparent,
      _ => _kEmptyPastColor,
    };
    // The two darkest shades need light text; anything lighter keeps the ink.
    final ink = switch (true) {
      _ when hasStudy && level >= 3 => Colors.white,
      _ when hasStudy => AppCustomColor.textPrimary,
      _ when isFuture => _kFutureInk,
      _ => _kEmptyPastInk,
    };

    final cell = Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9.r),
        border: switch (true) {
          _ when hasStudy => Border.all(color: _kStudyBorder, width: 0.75),
          _ when isFuture => Border.all(color: _kFutureBorder, width: 0.75),
          _ => null,
        },
        // Today's ring sits outside the square so it never eats into the
        // shade the square is there to communicate.
        boxShadow: isToday ? [const BoxShadow(color: AppCustomColor.brandPrimary, spreadRadius: 1.5)] : null,
      ),
      alignment: Alignment.center,
      child: AppText(
        '$day',
        style: _journalText(12, hasStudy ? FontWeight.w700 : FontWeight.w600, color: ink),
      ),
    );

    if (isFuture)
      return Semantics(
        label: context.l10n.studyJournal.dayFuture(day: day),
        child: cell,
      );

    return Semantics(
      button: true,
      label: '$day · ${context.l10n.studyJournal.daySemantics(count: keypoints)}',
      child: GestureDetector(onTap: () => onTap(date), child: cell),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(context.l10n.studyJournal.legendLess, style: _journalText(10, FontWeight.w600, color: AppCustomColor.textSecondary)),
            5.horizontalSpace,
            for (final color in _kLevelColors) ...[
              Container(
                width: 11.w,
                height: 11.w,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3.r)),
              ),
              5.horizontalSpace,
            ],
            AppText(context.l10n.studyJournal.legendMore, style: _journalText(10, FontWeight.w600, color: AppCustomColor.textSecondary)),
          ],
        ),
        Flexible(
          child: AppText(
            context.l10n.studyJournal.tapHint,
            textAlign: TextAlign.right,
            maxLines: 2,
            style: _journalText(10, FontWeight.w600, color: _kWeekdayInk),
          ),
        ),
      ],
    );
  }
}
