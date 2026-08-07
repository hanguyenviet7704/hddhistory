part of '../../habit.dart';

// Figma 11400:27785 / 11400:27777 stat icons — pulled from the design file.
const String _kHabitCompletionRateBase = 'assets/svg/common/habit_completion_rate_base.svg';
const String _kHabitCompletionRateOverlay = 'assets/svg/common/habit_completion_rate_overlay.svg';
const String _kHabitCurrentLoop = 'assets/svg/common/habit_current_loop.svg';

/// Corner radius shared by the habit detail cards — design "5 · Habit" uses 24
/// on all of them, noticeably rounder than the app's default 16/20 cards.
const double _kHabitCardRadius = 24;

/// The design's card lift: `0 6px 20px rgba(13,18,28,.05)`. Without it the cards
/// read as flat panels painted on the grey page instead of sitting above it.
List<BoxShadow> get _kHabitCardShadow => [
  BoxShadow(
    color: AppCustomColor.textPrimary.withValues(alpha: 0.05),
    blurRadius: 20,
    offset: const Offset(0, 6),
  ),
];

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

  /// "Read more on this": the courses teaching this habit's keypoints. Loaded
  /// alongside the diary; empty (failure included) simply renders no rail.
  List<HabitCourseEntity> _courses = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final cubit = context.read<HabitCubit>();
    unawaited(
      cubit.loadHabitCourses(widget.userHabit.habitId).then((courses) {
        if (mounted) setState(() => _courses = courses);
      }),
    );
    final checkins = await cubit.getCheckins(widget.userHabit.id);
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

    // Full-bleed, matching the design's `inset:0` overlay — it covers the whole
    // screen rather than stopping short like a partial-height sheet, and so has
    // no rounded top. Still presented via showModalBottomSheet
    // (isScrollControlled), which keeps the slide-up transition the design
    // animates with.
    //
    // Read the safe-area insets off the VIEW, not off MediaQuery.
    // `showModalBottomSheet` (useSafeArea: false, the default) wraps its child in
    // `MediaQuery.removePadding(removeTop: true)` so a sheet can slide under the
    // status bar — which zeroes `MediaQuery.viewPaddingOf` here and drew the
    // header's title straight over the clock and the notch. The view still knows
    // the real inset, and taking it from there keeps the background full-bleed
    // (as the design's `inset:0` overlay is) while the content clears the
    // hardware.
    final viewPadding = MediaQueryData.fromView(View.of(context)).viewPadding;
    return Container(
      height: 1.sh,
      color: AppCustomColor.backgroundGray,
      child: Column(
        children: [
          _header(context, habit, viewPadding.top),
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  // Bottom padding clears the pinned CTA (and the home indicator
                  // / Android nav bar) so the last card can always be scrolled
                  // out from under it.
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 120.h + viewPadding.bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // The design shows no status chip here — an active habit
                      // is the normal case and does not need labelling. A
                      // paused one does: nothing else on this sheet says why
                      // its streak stopped moving, so the chip stays for that
                      // case only.
                      if (!habit.isActive) ...[
                        _StatusPill(active: false),
                        16.verticalSpace,
                      ],
                      _StatsCard(completionRate: _completionRate, currentLoopDays: habit.currentStreak),
                      16.verticalSpace,
                      _RepetitionsSection(
                        startedAt: _startedAt,
                        doneDates: {
                          for (final c in (_checkins ?? []).where((c) => c.done)) DateUtils.dateOnly(c.date),
                        },
                        loading: _checkins == null,
                      ),
                      16.verticalSpace,
                      _DiarySection(entries: diary),
                      if (_courses.isNotEmpty) ...[
                        16.verticalSpace,
                        _ReadMoreSection(courses: _courses),
                      ],
                    ],
                  ),
                ),
                Positioned(left: 0, right: 0, bottom: 0, child: _practiceCta(context, viewPadding.bottom)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Sticky header: habit icon, title, close.
  ///
  /// The design blurs this bar because its content scrolls underneath an
  /// absolutely-positioned header. Here the header is a sibling in a Column, so
  /// nothing passes under it and a BackdropFilter would blur only its own opaque
  /// fill — same result, one less expensive layer.
  Widget _header(BuildContext context, UserHabitEntity habit, double topInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, topInset + 14.h, 20.w, 14.h),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundGray,
        border: Border(bottom: BorderSide(color: AppCustomColor.borderSecondary)),
      ),
      child: Row(
        children: [
          HabitDomainIcon(skillsetId: habit.habit?.skillsetId ?? '', imageUrl: habit.habit?.image ?? '', size: 38),
          12.horizontalSpace,
          Expanded(
            child: AppText(
              habit.displayTitle,
              maxLines: 2,
              // Design 15px/700 — rounded onto the app's scale, which has no 15.
              style: AppStyle.text16.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: AppCustomColor.textPrimary,
              ),
            ),
          ),
          8.horizontalSpace,
          Semantics(
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
        ],
      ),
    );
  }

  /// "Practice now" (design "5 · Habit" → Habit detail) — opens the "How do you
  /// want to check in?" picker. Pinned over the scroll behind a gradient fade,
  /// so content reads as passing under it rather than being cut off.
  Widget _practiceCta(BuildContext context, double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 26.h + bottomInset),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppCustomColor.backgroundGray.withValues(alpha: 0),
            AppCustomColor.backgroundGray,
          ],
          stops: const [0, 0.34],
        ),
      ),
      // Design: 58 tall, fully rounded, 18px/700 label, and a coloured lift
      // (`0 10px 24px rgba(85,79,240,.3)`) that makes it read as floating over
      // the scroll rather than being part of the last card.
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999.r),
          boxShadow: [
            BoxShadow(
              color: AppCustomColor.brandPrimary.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: DButton(
          backgroundColor: AppCustomColor.brandPrimary,
          size: Size.fromHeight(58.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999.r)),
          onPressed: _openPractice,
          customChild: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow_rounded, size: 22.w, color: AppCustomColor.textWhite),
              10.horizontalSpace,
              AppText(
                context.l10n.habit.practiceNowButton,
                style: AppStyle.text18.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppCustomColor.textWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Practice now" → "How do you want to check in?" → journal or quiz.
  ///
  /// Practices are fetched before the sheet opens so the quiz row can be hidden
  /// when the habit has no playable published content — which is most habits
  /// until someone attaches an exercise in admin.
  Future<void> _openPractice() async {
    AppHaptic.select();
    final habitId = widget.userHabit.habit?.id.isNotEmpty == true
        ? widget.userHabit.habit!.id
        : widget.userHabit.habitId;
    final practices = await context.read<HabitCubit>().loadPractices(habitId);
    if (!mounted) return;

    final choice = await PracticePickSheet.show(context, practices: practices);
    if (choice == null || !mounted) return;

    bool? saved;
    if (choice == PracticeChoice.journal) {
      saved = await JournalCheckInPage.push(context, userHabit: widget.userHabit);
    } else {
      final playable = practices.where((practice) => practice.isPlayable).firstOrNull;
      // Only reachable if the sheet offered quiz, which requires a playable
      // practice — but resolve defensively rather than with a throwing `first`.
      if (playable == null) return;
      saved = await HabitQuizPage.push(
        context,
        userHabit: widget.userHabit,
        practice: playable,
      );
      // The design's payoff screen ("3 · Practice complete" — Habit is
      // growing!) follows EVERY completed practice; the journal path pushes it
      // from inside its own page, the quiz reports back with `saved` instead.
      if (saved == true && mounted) {
        await PracticeDonePage.push(context, userHabit: widget.userHabit);
      }
    }

    // Re-read the log so the heatmap and diary pick up what was just written.
    if (saved == true && mounted) await _load();
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
      padding: EdgeInsets.symmetric(vertical: 24.h),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(_kHabitCardRadius.r),
        boxShadow: _kHabitCardShadow,
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
            // `width` is the divider's whole horizontal extent, with the 1px
            // line centred in it — so 22 + 1 + 22 reproduces the design's
            // `margin: 0 22px` around the hairline. Passing width:1 put the two
            // cells hard against the line.
            VerticalDivider(
              width: 45.w,
              thickness: 1,
              color: AppCustomColor.borderDefault,
            ),
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
    // Design: label 14/600 muted, value 22/700 — the numbers are the point of
    // this card, so they carry the size.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(
          label,
          maxLines: 1,
          style: AppStyle.text14.copyWith(
            fontWeight: FontWeight.w600,
            color: AppCustomColor.textTertiary,
          ),
        ),
        8.verticalSpace,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            8.horizontalSpace,
            AppText(
              value,
              style: AppStyle.text22.copyWith(
                fontWeight: FontWeight.w700,
                color: AppCustomColor.textPrimary,
              ),
            ),
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
    // Design pads this card `26px 0 26px 24px` — no right padding, so the month
    // strip bleeds to the card edge and reads as scrollable. Reproduced with an
    // asymmetric padding plus the scroll view's own trailing inset.
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24.w, 26.h, 0, 26.h),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(_kHabitCardRadius.r),
        boxShadow: _kHabitCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            context.l10n.habit.detailTotalRepetitions,
            style: AppStyle.text20.copyWith(
              fontWeight: FontWeight.w700,
              color: AppCustomColor.textPrimary,
            ),
          ),
          4.verticalSpace,
          AppText(
            context.l10n.habit.detailSince(date: startedAt.parseString('MMM d, yyyy')),
            style: AppStyle.text14.copyWith(color: AppCustomColor.textTertiary),
          ),
          22.verticalSpace,
          if (loading)
            SizedBox(
              height: 120.h,
              child: const Center(child: CircularProgressIndicator()),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(right: 24.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < _months.length; i++) ...[
                    if (i > 0) 34.horizontalSpace,
                    _MonthHeatmap(month: _months[i], startedAt: startedAt, doneDates: doneDates),
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

    // Design grid: seven 26px columns with an 8px gutter, so a row is
    // 26*7 + 8*6 = 230 wide. Previously the cells were 26 boxes with 2px of
    // internal padding, which made them 22 visually and the gaps 4 — a tighter,
    // smaller grid than the design's chunky one.
    const double cell = 26;
    const double gap = 8;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          month.parseString('MMMM'),
          style: AppStyle.text16.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w700),
        ),
        12.verticalSpace,
        Row(
          children: [
            for (int i = 0; i < weekdays.length; i++) ...[
              if (i > 0) gap.horizontalSpace,
              SizedBox(
                width: cell.w,
                child: Center(
                  child: AppText(
                    weekdays[i],
                    style: AppStyle.text13.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppCustomColor.textTertiary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        10.verticalSpace,
        SizedBox(
          width: cell.w * 7 + gap.w * 6,
          child: Wrap(
            spacing: gap.w,
            runSpacing: gap.w,
            children: cells
                .map((c) => SizedBox(width: cell.w, height: cell.w, child: c))
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
        borderRadius: BorderRadius.circular(7.r),
      ),
    );
  }
}

class _DiarySection extends StatelessWidget {
  final List<HabitCheckinEntity> entries;
  const _DiarySection({required this.entries});

  /// How many rows the card previews before deferring to the full-diary sheet,
  /// per the design's 3-entry preview. A long-running habit accumulates a row
  /// per day, and the card sits above the "Practice now" CTA — left unbounded it
  /// pushes the rest of the sheet into a scroll nobody reaches the bottom of.
  static const int _previewLimit = 3;

  @override
  Widget build(BuildContext context) {
    final preview = entries.take(_previewLimit).toList();
    final hasMore = entries.length > preview.length;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 20.h),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(_kHabitCardRadius.r),
        boxShadow: _kHabitCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: AppText(
                  context.l10n.habit.detailDiaryTitle,
                  style: AppStyle.text20.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppCustomColor.textPrimary,
                  ),
                ),
              ),
              // Count of every entry, not of the preview — it is what tells the
              // user there is more behind "View all".
              if (entries.isNotEmpty)
                AppText(
                  context.l10n.habit.detailDiaryCount(count: '${entries.length}'),
                  style: AppStyle.text14.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppCustomColor.textTertiary,
                  ),
                ),
            ],
          ),
          4.verticalSpace,
          if (entries.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: AppText(
                context.l10n.habit.detailDiaryEmpty,
                style: AppStyle.text14.copyWith(color: AppCustomColor.textTertiary),
              ),
            )
          else
            // No separators between preview rows: the design spaces them with
            // padding alone here and reserves the hairline for the full-diary
            // sheet, where the list is long enough to need one.
            for (final entry in preview) HabitDiaryRow(entry: entry),
          if (hasMore)
            Center(
              child: Semantics(
                button: true,
                child: GestureDetector(
                  onTap: () {
                    AppHaptic.select();
                    HabitDiaryAllSheet.show(context, entries: entries);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText(
                          context.l10n.habit.detailDiaryViewAll,
                          style: AppStyle.text16.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppCustomColor.brandPrimary,
                          ),
                        ),
                        6.horizontalSpace,
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18.w,
                          color: AppCustomColor.brandPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Read more on this" (design "5 · Habit" → Habit overview): the courses
/// whose keypoints teach this habit, as a horizontal rail of course cards.
/// Tapping one opens its roadmap through the same selection flow My Courses
/// uses — the sheet closes first so the roadmap isn't revealed underneath it.
/// The white "N% complete" pill the design overlays on a rail card's artwork.
///
/// The rail only carries a course id, so progress is read from what Home and
/// ProgressCubit already hold rather than asked of the habit endpoint — the
/// same two sources the My Courses and Explore cards read.
///
/// Deliberately narrower than [CourseProgressChip]'s inline cousin in the course
/// feature: this renders ONLY the in-progress state. A course the reader has not
/// started, or has finished, shows no pill at all, because on a "read more"
/// suggestion rail the pill is there to say "you were partway through this", and
/// a "0%" badge on every unstarted suggestion is noise. Hidden too when the
/// course is not in Home's data, which is the case before Home has loaded.
class _CourseBadgeChip extends StatelessWidget {
  final String courseId;
  const _CourseBadgeChip({required this.courseId});

  @override
  Widget build(BuildContext context) {
    final skillsets = AppDI.injector.get<HomeCubit>().state.skillsets;
    final course = skillsets.resolveCourseByCourseId(courseId);
    final total = course.numberOfLesson;
    if (course.id.isEmpty || total <= 0) return const SizedBox.shrink();

    final userProgress = context
        .watch<ProgressCubit>()
        .state
        .userProgresses
        .where((p) => p.courseId == courseId)
        .firstOrNull;
    final completed = userProgress?.lessonsResult.where((r) => r.passed).length ?? 0;
    final percent = (completed / total * 100).toInt();
    if (percent <= 0 || completed >= total) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.fromLTRB(6.w, 4.h, 9.w, 4.h),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(99.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 13.w,
            height: 13.w,
            child: CircularProgressIndicator(
              value: completed / total,
              strokeWidth: 2.w,
              backgroundColor: AppCustomColor.borderDefault,
              valueColor: AlwaysStoppedAnimation(AppCustomColor.brandPrimary),
            ),
          ),
          4.horizontalSpace,
          AppText(
            context.l10n.allcourse.progressPercent(percent: '$percent'),
            style: AppStyle.text10.copyWith(
              fontWeight: FontWeight.w700,
              color: AppCustomColor.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadMoreSection extends StatelessWidget {
  final List<HabitCourseEntity> courses;
  const _ReadMoreSection({required this.courses});

  void _openCourse(BuildContext context, HabitCourseEntity course) {
    AppHaptic.select();
    final homeCubit = AppDI.injector.get<HomeCubit>();
    final skillsets = homeCubit.state.skillsets;
    final resolved = skillsets.resolveCourseByCourseId(course.id);
    if (resolved.id.isEmpty) return;
    final skillset = skillsets.where((s) => s.id == course.skillsetId).firstOrNull ?? skillsets.where((s) => s.courses.any((c) => c.id == course.id)).firstOrNull;
    if (skillset == null) return;

    Navigator.of(context, rootNavigator: true).pop();
    final shellContext = AppConfig.instance.context;
    if (shellContext == null) return;
    AppDI.injector.get<CourseRoadmapCubit>().setRoadmapSource('habit_detail');
    homeCubit
      ..selectSkillset(skillset)
      ..selectCourse(resolved);
    CourseRoadmapRoute().go(shellContext);
    AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 0, 16.h),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(_kHabitCardRadius.r),
        boxShadow: _kHabitCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            context.l10n.habit.habitReadMoreTitle,
            style: AppStyle.textBold16.copyWith(color: AppCustomColor.textPrimary),
          ),
          4.verticalSpace,
          AppText(
            context.l10n.habit.habitReadMoreSubtitle,
            // Muted, not brand: in the design this line is a caption under the
            // heading, and brand ink read as a tappable link it never was.
            style: AppStyle.text14.copyWith(fontWeight: FontWeight.w500, color: AppCustomColor.textTertiary),
          ),
          16.verticalSpace,
          SizedBox(
            // Square artwork (132) + title block + meta line.
            height: 212.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(right: 16.w),
              itemCount: courses.length,
              separatorBuilder: (_, __) => 12.horizontalSpace,
              itemBuilder: (context, index) => _courseCard(context, courses[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _courseCard(BuildContext context, HabitCourseEntity course) {
    return Semantics(
      button: true,
      label: course.title.text,
      child: GestureDetector(
        onTap: () => _openCourse(context, course),
        child: SizedBox(
          width: 132.w,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: SizedBox(
                  // Square in the design, where it was 132x92 here — the crop
                  // was cutting the top off every course illustration.
                  height: 132.w,
                  width: 132.w,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          color: AppCustomColor.brandPrimary50,
                          child: course.image.isEmpty
                              ? Icon(Icons.menu_book_rounded, size: 30.w, color: AppCustomColor.brandPrimary)
                              : CachedNetworkImage(
                                  imageUrl: course.image,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Icon(Icons.menu_book_rounded, size: 30.w, color: AppCustomColor.brandPrimary),
                                ),
                        ),
                      ),
                      Positioned(top: 10.r, left: 10.r, child: _CourseBadgeChip(courseId: course.id)),
                      if ((course.viewCount ?? 0) > 0)
                        Positioned(
                          right: 9.r,
                          bottom: 9.r,
                          child: CourseViewsChip(count: course.viewCount!),
                        ),
                    ],
                  ),
                ),
              ),
              8.verticalSpace,
              // Fixed height for the title block so the meta lines of adjacent
              // cards sit on one baseline whether a title wraps to one line or
              // two — the design's `min-height:36px`.
              SizedBox(
                height: 36.h,
                child: AppText(
                  course.title.text,
                  maxLines: 2,
                  style: AppStyle.text13.copyWith(fontWeight: FontWeight.w600, height: 1.35, color: AppCustomColor.textPrimary),
                ),
              ),
              if (course.author.isNotEmpty) ...[
                6.verticalSpace,
                CourseAuthorLine(author: course.author),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
