part of '../../study_journal.dart';

/// One day of the journal: the lessons finished and the habits practised
/// (design `6 · Profile` — "Chi tiết ngày học").
///
/// Opened by tapping a square in [StudyJournalCalendar].
class StudyJournalDaySheet extends StatefulWidget {
  const StudyJournalDaySheet({super.key, required this.day, required this.cubit});

  final DateTime day;
  final StudyJournalCubit cubit;

  static Future<void> show(
    BuildContext context, {
    required DateTime day,
    required StudyJournalCubit cubit,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StudyJournalDaySheet(day: day, cubit: cubit),
    );
  }

  @override
  State<StudyJournalDaySheet> createState() => _StudyJournalDaySheetState();
}

class _StudyJournalDaySheetState extends State<StudyJournalDaySheet> {
  StudyJournalDayDetailEntity? _detail;
  bool _isLoading = true;
  bool _hasFailed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final detail = await widget.cubit.loadDay(widget.day);
    if (!mounted) return;
    setState(() {
      _detail = detail;
      // A failed fetch and a rest day look identical in an empty list, so they
      // are tracked apart: one offers a retry, the other says nothing happened.
      _hasFailed = detail == null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;

    return Container(
      constraints: BoxConstraints(maxHeight: 0.78.sh),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xFFE3E5EC),
                borderRadius: BorderRadius.circular(99.r),
              ),
            ),
          ),
          14.verticalSpace,
          _Header(day: widget.day, detail: detail, isLoading: _isLoading, hasFailed: _hasFailed),
          18.verticalSpace,
          // The sheet is laid out at loading height and again at content
          // height; without this the second layout lands as a jerk right after
          // the sheet has finished sliding up. Animating the difference makes
          // one motion out of two.
          Flexible(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _body(detail),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(StudyJournalDayDetailEntity? detail) {
    if (_isLoading) {
      // Sized to roughly what a short day occupies, so the settle is a nudge
      // rather than a collapse from half the screen.
      return SizedBox(
        height: 150.h,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_hasFailed || detail == null) {
      return _Message(text: context.l10n.studyJournal.dayError, onRetry: _retry);
    }
    if (detail.isEmpty) return const _RestDay();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (detail.courses.isNotEmpty) ...[
            _SectionLabel(text: context.l10n.studyJournal.sectionLessons),
            10.verticalSpace,
            for (final (index, course) in detail.courses.indexed) ...[
              _CourseRow(course: course, index: index, onTap: () => _openCourse(course)),
              12.verticalSpace,
            ],
          ],
        ],
      ),
    );
  }

  /// Course row → that course's roadmap.
  ///
  /// The journal only knows the course id, so the entity is fetched before
  /// navigating: the roadmap is driven by HomeCubit's selected skillset+course
  /// (same contract as Library's own open — see `library_page._openCourse`),
  /// and a half-filled selection would land the user on somebody else's map.
  Future<void> _openCourse(StudyJournalCourseEntity course) async {
    if (course.courseId.isEmpty) return;
    final navigator = Navigator.of(context);
    final shellContext = navigator.context;

    final result = await AppDI.injector.get<GetCourseUseCase>()(course.courseId).run();
    if (!mounted) return;

    result.match((_) => null, (entity) {
      // Close the sheet FIRST: the roadmap is a shell branch, and pushing the
      // tab change under an open modal leaves the sheet floating over it.
      navigator.pop();
      final resolved = entity.withSkillset;
      AppDI.injector.get<CourseRoadmapCubit>().setRoadmapSource(kRoadmapSourceStudyJournal);
      AppDI.injector.get<HomeCubit>()
        ..selectSkillset(resolved.skillset)
        ..selectCourse(resolved);
      CourseRoadmapRoute().go(shellContext);
      // `.go()` into an already-built branch fires no didPush, so the observer
      // would leave the nav state on Profile without this re-anchor.
      shellContext.read<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
      return null;
    });
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _hasFailed = false;
    });
    unawaited(_load());
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.day,
    required this.detail,
    required this.isLoading,
    required this.hasFailed,
  });

  final DateTime day;
  final StudyJournalDayDetailEntity? detail;
  final bool isLoading;
  final bool hasFailed;

  @override
  Widget build(BuildContext context) {
    final journal = context.l10n.studyJournal;
    final subtitle = _subtitle(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                journal.dayTitle(
                  weekday: _weekdayName(context, day.weekday),
                  day: day.day,
                  month: day.month,
                ),
                style: _journalText(19, FontWeight.w700),
              ),
              // Dropped entirely on failure rather than filled with a
              // placeholder: the body already carries the error, and a summary
              // line there would be a second, quieter claim about the same day.
              if (subtitle.isNotEmpty) ...[
                4.verticalSpace,
                AppText(
                  subtitle,
                  style: _journalText(12.5, FontWeight.w600, color: AppCustomColor.brandPrimary),
                ),
              ],
            ],
          ),
        ),
        8.horizontalSpace,
        // Explicit close button as in the design: the sheet is reached from a
        // small calendar square, and a drag-down is not obvious enough to be
        // the only way back out of it.
        Semantics(
          button: true,
          label: context.l10n.common.close,
          child: GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 30.w,
              height: 30.w,
              decoration: const BoxDecoration(color: Color(0xFFF1F2F6), shape: BoxShape.circle),
              child: Icon(Icons.close_rounded, size: 18.sp, color: const Color(0xFF6B7688)),
            ),
          ),
        ),
      ],
    );
  }

  String _subtitle(BuildContext context) {
    final journal = context.l10n.studyJournal;
    if (hasFailed) return '';
    final data = detail;
    if (isLoading || data == null) return journal.dayLoading;
    if (data.isEmpty) return journal.dayRest;

    // Lessons and minutes only, exactly as the design: the habits are their own
    // titled section right below, and counting them up here would say the same
    // thing twice while pushing the line past the close button on long dates.
    final parts = <String>[
      if (data.lessons > 0) journal.lessonCount(count: data.lessons),
      if (data.minutes > 0) journal.minuteCount(count: data.minutes),
    ];

    return parts.join(' · ');
  }
}

/// Full weekday name for the sheet title ("Thứ Năm, 2 tháng 7").
///
/// Read out of one comma-separated l10n string rather than seven keys: the
/// order IS the data (Monday first, matching `weekdays` and the calendar grid),
/// and seven separate keys let a translator reorder them by accident.
String _weekdayName(BuildContext context, int weekday) {
  final names = context.l10n.studyJournal.weekdayNames.split(',');
  final index = (weekday - DateTime.monday).clamp(0, names.length - 1);

  return names[index].trim();
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return AppText(
      text.toUpperCase(),
      style: _journalText(11, FontWeight.w800, color: const Color(0xFF9AA4B2)),
    );
  }
}

class _CourseRow extends StatelessWidget {
  const _CourseRow({required this.course, required this.index, required this.onTap});

  final StudyJournalCourseEntity course;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final journal = context.l10n.studyJournal;
    final parts = <String>[
      journal.lessonCount(count: course.lessons),
      if (course.minutes > 0) journal.minuteCount(count: course.minutes),
    ];

    return Semantics(
      button: true,
      label: course.title,
      // No chevron by design: the whole row is the target (opaque hit test
      // above), and `Semantics(button: true)` is what tells a screen reader so.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptic.select();
          onTap();
        },
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: SizedBox(
                width: 44.w,
                height: 44.w,
                child: course.image.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: _safeImageUrl(course.image),
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => _LessonPlaceholder(seed: index),
                        placeholder: (_, _) => _LessonPlaceholder(seed: index),
                      )
                    : _LessonPlaceholder(seed: index),
              ),
            ),
            12.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(course.title, maxLines: 2, style: _journalText(14.5, FontWeight.w700)),
                  3.verticalSpace,
                  AppText(
                    parts.join(' · '),
                    maxLines: 1,
                    style: _journalText(12, FontWeight.w500, color: const Color(0xFF7C8AA4)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Keypoint artwork is authored with raw spaces in the path
/// (`.../keypoints/What is Modern Art.png`), which Dio rejects as an invalid
/// URI — the row then falls back to a tile even though the image exists.
/// Encoded here rather than in the endpoint so every such row is covered
/// whatever the server happens to send.
String _safeImageUrl(String url) => url.contains(' ') ? Uri.encodeFull(url) : url;

/// Rotating pastel tints for rows whose course has no artwork, so a list
/// missing images reads as several lessons rather than one repeated chip.
const List<List<Color>> _kPlaceholderTints = [
  [Color(0xFFFBF6EA), Color(0xFFB5860F)],
  [Color(0xFFFDEEE3), Color(0xFFD9803F)],
  [Color(0xFFE4F6EE), Color(0xFF2E9E76)],
  [Color(0xFFFCE7F0), Color(0xFFC94F86)],
  [Color(0xFFE6F1FD), Color(0xFF3B7DD8)],
];

class _LessonPlaceholder extends StatelessWidget {
  const _LessonPlaceholder({this.seed = 0});

  final int seed;

  @override
  Widget build(BuildContext context) {
    final tint = _kPlaceholderTints[seed % _kPlaceholderTints.length];

    return Container(
      color: tint[0],
      alignment: Alignment.center,
      child: Icon(Icons.auto_stories_rounded, size: 20.sp, color: tint[1]),
    );
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({required this.habit, required this.onTap});

  final StudyJournalHabitEntity habit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: habit.title,
      // No chevron by design: the whole row is the target (opaque hit test
      // above), and `Semantics(button: true)` is what tells a screen reader so.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptic.select();
          onTap();
        },
        child: Row(
          children: [
            // The habit's own library artwork, with the tick tile standing in only
            // when a habit has none — the row has to look like the habit it names,
            // not like a generic completed thing.
            ClipRRect(
              borderRadius: BorderRadius.circular(11.r),
              child: SizedBox(
                width: 38.w,
                height: 38.w,
                child: habit.image.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: _safeImageUrl(habit.image),
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => const _HabitCheckTile(),
                        placeholder: (_, _) => const _HabitCheckTile(),
                      )
                    : const _HabitCheckTile(),
              ),
            ),
            12.horizontalSpace,
            Expanded(
              child: AppText(habit.title, maxLines: 2, style: _journalText(14.5, FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitCheckTile extends StatelessWidget {
  const _HabitCheckTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFDFF3E8),
      alignment: Alignment.center,
      child: Icon(Icons.check_rounded, size: 19.sp, color: const Color(0xFF2E9E76)),
    );
  }
}

/// A day with nothing on it — the design's "ngày nghỉ" state.
///
/// Deliberately warm rather than a bare "no data" line: the calendar invites
/// tapping every square, so most visits to this state are curiosity, not a
/// mistake, and the day off is worth saying out loud.
class _RestDay extends StatelessWidget {
  const _RestDay();

  @override
  Widget build(BuildContext context) {
    final journal = context.l10n.studyJournal;

    return Padding(
      padding: EdgeInsets.only(top: 12.h, bottom: 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64.w,
            height: 64.w,
            decoration: const BoxDecoration(color: Color(0xFFFBF7EE), shape: BoxShape.circle),
            // Outline crescent, not the filled glyph: in the design the moon
            // reads as a line drawing inside the tile, and the solid version
            // came out as a dark blob at this size.
            child: Icon(Icons.dark_mode_outlined, size: 30.sp, color: AppCustomColor.brandPrimary),
          ),
          16.verticalSpace,
          AppText(
            journal.dayEmptyTitle,
            textAlign: TextAlign.center,
            style: _journalText(15.5, FontWeight.w700),
          ),
          6.verticalSpace,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: AppText(
              journal.dayEmptyBody,
              textAlign: TextAlign.center,
              maxLines: 3,
              style: _journalText(12.5, FontWeight.w500, color: const Color(0xFF7C8AA4)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 30.h),
      // Without this the Column takes the sheet's whole max height and the
      // error floats in a screen of white.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            text,
            textAlign: TextAlign.center,
            style: _journalText(13.5, FontWeight.w500, color: const Color(0xFF7C8AA4)),
          ),
          if (onRetry != null) ...[
            12.verticalSpace,
            TextButton(
              onPressed: onRetry,
              child: AppText(
                context.l10n.studyJournal.retry,
                style: _journalText(13.5, FontWeight.w700, color: AppCustomColor.brandPrimary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
