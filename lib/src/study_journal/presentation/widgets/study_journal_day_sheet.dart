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
          Flexible(child: _body(detail)),
        ],
      ),
    );
  }

  Widget _body(StudyJournalDayDetailEntity? detail) {
    if (_isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_hasFailed || detail == null) {
      return _Message(text: context.l10n.studyJournal.dayError, onRetry: _retry);
    }
    if (detail.isEmpty) return _Message(text: context.l10n.studyJournal.dayEmpty);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (detail.lessons.isNotEmpty) ...[
            _SectionLabel(text: context.l10n.studyJournal.sectionLessons),
            10.verticalSpace,
            for (final (index, lesson) in detail.lessons.indexed) ...[
              _LessonRow(item: lesson, index: index),
              12.verticalSpace,
            ],
          ],
          if (detail.habits.isNotEmpty) ...[
            if (detail.lessons.isNotEmpty) 8.verticalSpace,
            _SectionLabel(text: context.l10n.studyJournal.sectionHabits),
            10.verticalSpace,
            for (final habit in detail.habits) ...[
              _HabitRow(habit: habit),
              12.verticalSpace,
            ],
          ],
        ],
      ),
    );
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
      if (data.lessons.isNotEmpty) journal.lessonCount(count: data.lessons.length),
      if (data.minutes > 0) journal.minuteCount(count: data.minutes),
      if (data.lessons.isEmpty && data.habits.isNotEmpty) journal.habitCount(count: data.habits.length),
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

class _LessonRow extends StatelessWidget {
  const _LessonRow({required this.item, required this.index});

  final StudyJournalItemEntity item;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: SizedBox(
            width: 44.w,
            height: 44.w,
            child: item.image.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: _safeImageUrl(item.image),
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
              AppText(item.title, maxLines: 2, style: _journalText(14.5, FontWeight.w700)),
              if (item.courseTitle.isNotEmpty) ...[
                3.verticalSpace,
                AppText(
                  item.courseTitle,
                  maxLines: 1,
                  style: _journalText(12, FontWeight.w500, color: const Color(0xFF7C8AA4)),
                ),
              ],
            ],
          ),
        ),
      ],
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
  [Color(0xFFECEAFB), Color(0xFF554FF0)],
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
  const _HabitRow({required this.habit});

  final StudyJournalHabitEntity habit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34.w,
          height: 34.w,
          decoration: BoxDecoration(
            color: const Color(0xFFDFF3E8),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(Icons.check_rounded, size: 19.sp, color: const Color(0xFF2E9E76)),
        ),
        12.horizontalSpace,
        Expanded(
          child: AppText(habit.title, maxLines: 2, style: _journalText(14.5, FontWeight.w700)),
        ),
      ],
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
      child: Column(
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
