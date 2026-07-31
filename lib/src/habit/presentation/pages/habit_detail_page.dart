part of '../../habit.dart';

// Figma 11400:27785 / 11400:27777 stat icons — pulled from the design file.
const String _kHabitCompletionRateBase = 'assets/svg/common/habit_completion_rate_base.svg';
const String _kHabitCompletionRateOverlay = 'assets/svg/common/habit_completion_rate_overlay.svg';
const String _kHabitCurrentLoop = 'assets/svg/common/habit_current_loop.svg';

/// Habit detail (Figma `11395:27559` "Habit overview"): status, stats
/// (completion rate | current loop), a month-by-month repetition heatmap
/// (swipe across months, 3 cell states), and the habit diary. Opened as a
/// near-full-height modal sheet (not a pushed page) from a tracker row tap.
class HabitDetailPage extends StatefulWidget {
  final UserHabitEntity userHabit;

  const HabitDetailPage({super.key, required this.userHabit});

  static Future<void> show(BuildContext context, {required UserHabitEntity userHabit}) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: AppDI.injector.get<HabitCubit>(),
        child: HabitDetailPage(userHabit: userHabit),
      ),
    );
  }

  @override
  State<HabitDetailPage> createState() => _HabitDetailPageState();
}

class _HabitDetailPageState extends State<HabitDetailPage> {
  List<HabitCheckinEntity>? _checkins;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final checkins = await context.read<HabitCubit>().getCheckins(widget.userHabit.id);
    if (!mounted) return;
    setState(() => _checkins = checkins);
    HabitTracking.detailScrView(widget.userHabit, completionRate: _completionRate, currentLoops: widget.userHabit.currentStreak);
  }

  DateTime get _startedAt => widget.userHabit.startedAt ?? _checkins?.lastOrNull?.date ?? DateTime.now();

  int get _completionRate {
    final checkins = _checkins;
    if (checkins == null || checkins.isEmpty) return 0;
    final doneDays = checkins.where((c) => c.done).length;
    final start = DateUtils.dateOnly(_startedAt);
    final today = DateUtils.dateOnly(DateTime.now());
    final totalDays = today.difference(start).inDays + 1;
    if (totalDays <= 0) return 0;
    return ((doneDays / totalDays) * 100).round().clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.userHabit;
    // Every check-in is a diary entry (§9.8): those with a note show it, those
    // without show a muted "Checked in" line so a note-less check-in isn't
    // invisible. Filter on `done` so a (legacy/future) un-done record can't
    // masquerade as a check-in.
    final diary = (_checkins ?? []).where((c) => c.done).toList();

    // Bake the bottom safe-area inset into the container's own padding
    // instead of wrapping in SafeArea — that keeps the gray sheet flush to
    // the bottom edge (no transparent gap showing under it) while content
    // still clears the home indicator / Android nav bar.
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      constraints: BoxConstraints(maxHeight: 0.91.sh),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h + bottomInset),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundGray,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Semantics(
              button: true,
              label: context.l10n.common.close,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.close, size: 24.w, color: AppCustomColor.textTertiary),
                onPressed: () {
                  AppHaptic.select();
                  HabitTracking.detailClose();
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
          8.verticalSpace,
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HabitDomainIcon(skillsetId: habit.habit?.skillsetId ?? '', size: 48),
                  6.verticalSpace,
                  AppText(
                    habit.displayTitle,
                    style: AppStyle.textBold24.copyWith(color: AppCustomColor.textPrimary),
                  ),
                  12.verticalSpace,
                  _StatusPill(active: habit.isActive),
                  20.verticalSpace,
                  _StatsCard(completionRate: _completionRate, currentLoopDays: habit.currentStreak),
                  20.verticalSpace,
                  _RepetitionsSection(
                    startedAt: _startedAt,
                    doneDates: {
                      for (final c in (_checkins ?? []).where((c) => c.done)) DateUtils.dateOnly(c.date),
                    },
                    loading: _checkins == null,
                  ),
                  8.verticalSpace,
                  _DiarySection(entries: diary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool active;
  const _StatusPill({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(1000.r),
      ),
      child: AppText(
        active ? context.l10n.habit.editActiveLabel : context.l10n.habit.editInactiveLabel,
        style: AppStyle.text10.copyWith(
          color: AppCustomColor.textTertiary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final int completionRate;
  final int currentLoopDays;
  const _StatsCard({required this.completionRate, required this.currentLoopDays});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _StatCell(
                label: context.l10n.habit.detailCompletionRate,
                icon: SizedBox(
                  width: 24.w,
                  height: 24.w,
                  child: Stack(
                    children: [
                      SvgPicture.asset(_kHabitCompletionRateBase, width: 24.w, height: 24.w),
                      SvgPicture.asset(_kHabitCompletionRateOverlay, width: 24.w, height: 24.w),
                    ],
                  ),
                ),
                value: '$completionRate%',
              ),
            ),
            VerticalDivider(width: 1, color: AppCustomColor.borderDefault),
            Expanded(
              child: _StatCell(
                label: context.l10n.habit.detailCurrentLoop,
                icon: SvgPicture.asset(_kHabitCurrentLoop, width: 24.w, height: 24.w),
                value: context.l10n.habit.detailCurrentLoopValue(days: currentLoopDays),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final Widget icon;
  final String value;
  const _StatCell({required this.label, required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(label, style: AppStyle.text12.copyWith(color: AppCustomColor.textTertiary)),
        8.verticalSpace,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            6.horizontalSpace,
            AppText(value, style: AppStyle.textBold16.copyWith(color: AppCustomColor.textPrimary)),
          ],
        ),
      ],
    );
  }
}

class _RepetitionsSection extends StatelessWidget {
  final DateTime startedAt;
  final Set<DateTime> doneDates;
  final bool loading;

  const _RepetitionsSection({required this.startedAt, required this.doneDates, required this.loading});

  List<DateTime> get _months {
    final start = DateTime(startedAt.year, startedAt.month);
    final now = DateTime.now();
    final end = DateTime(now.year, now.month);
    final months = <DateTime>[];
    var m = start;
    while (!m.isAfter(end) && months.length < 24) {
      months.add(m);
      m = DateTime(m.year, m.month + 1);
    }
    return months.isEmpty ? [end] : months;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            context.l10n.habit.detailTotalRepetitions,
            style: AppStyle.textBold16.copyWith(color: AppCustomColor.textPrimary),
          ),
          4.verticalSpace,
          AppText(
            context.l10n.habit.detailSince(date: startedAt.parseString('MMM d, yyyy')),
            style: AppStyle.text12.copyWith(color: AppCustomColor.textTertiary),
          ),
          16.verticalSpace,
          if (loading)
            SizedBox(
              height: 120.h,
              child: const Center(child: CircularProgressIndicator()),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final month in _months) ...[
                    _MonthHeatmap(month: month, startedAt: startedAt, doneDates: doneDates),
                    20.horizontalSpace,
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// One month grid: weekday header (Mon-first) + day cells with 3 states —
/// future (outline only), missed (light), done (dark) — per PRD FR8.3.
class _MonthHeatmap extends StatelessWidget {
  final DateTime month;
  final DateTime startedAt;
  final Set<DateTime> doneDates;

  const _MonthHeatmap({required this.month, required this.startedAt, required this.doneDates});

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(month.year, month.month);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final leadingBlanks = firstOfMonth.weekday - 1; // Mon=1 -> 0 blanks
    final today = DateUtils.dateOnly(DateTime.now());
    final start = DateUtils.dateOnly(startedAt);
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final cells = <Widget>[];
    for (var i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      cells.add(_cell(date, today, start));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          month.parseString('MMMM'),
          style: AppStyle.text12.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w700),
        ),
        12.verticalSpace,
        Row(
          children: weekdays
              .map(
                (d) => SizedBox(
                  width: 26.w,
                  child: Center(
                    child: AppText(d, style: AppStyle.text10.copyWith(color: AppCustomColor.textTertiary)),
                  ),
                ),
              )
              .toList(),
        ),
        8.verticalSpace,
        SizedBox(
          width: 26.w * 7,
          child: Wrap(
            children: cells
                .map(
                  (c) => SizedBox(
                    width: 26.w,
                    height: 26.w,
                    child: Padding(padding: EdgeInsets.all(2.w), child: c),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _cell(DateTime date, DateTime today, DateTime start) {
    final isFuture = date.isAfter(today) || date.isBefore(start);
    final done = doneDates.contains(date);
    final Color color;
    Border? border;
    if (isFuture) {
      color = Colors.transparent;
      border = Border.all(color: AppCustomColor.borderSecondary, width: 1.5);
    } else if (done) {
      color = AppCustomColor.streakActive;
    } else {
      color = AppCustomColor.brandPrimary50;
    }
    return Container(
      decoration: BoxDecoration(
        color: color,
        border: border,
        borderRadius: BorderRadius.circular(6.r),
      ),
    );
  }
}

class _DiarySection extends StatelessWidget {
  final List<HabitCheckinEntity> entries;
  const _DiarySection({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            context.l10n.habit.detailDiaryTitle,
            style: AppStyle.textBold16.copyWith(color: AppCustomColor.textPrimary),
          ),
          16.verticalSpace,
          if (entries.isEmpty)
            AppText(
              context.l10n.habit.detailDiaryEmpty,
              style: AppStyle.text14.copyWith(color: AppCustomColor.textTertiary),
            )
          else
            for (int i = 0; i < entries.length; i++) ...[
              if (i > 0) Divider(height: 20.h, color: AppCustomColor.borderDefault),
              Builder(
                builder: (context) {
                  // A check-in with no note still logs as a diary entry, shown
                  // as a muted "Checked in" so it reads as a system label, not
                  // user-written content.
                  final note = entries[i].note?.trim() ?? '';
                  final hasNote = note.isNotEmpty;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 52.w,
                        child: AppText(
                          entries[i].date.parseString('d/M/yy'),
                          style: AppStyle.text12.copyWith(color: AppCustomColor.textTertiary),
                        ),
                      ),
                      12.horizontalSpace,
                      Expanded(
                        child: AppText(
                          hasNote ? note : context.l10n.habit.detailDiaryCheckedIn,
                          style: AppStyle.text14.copyWith(
                            color: hasNote ? AppCustomColor.textPrimary : AppCustomColor.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
        ],
      ),
    );
  }
}
