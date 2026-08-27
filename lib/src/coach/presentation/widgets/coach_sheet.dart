part of '../../coach.dart';

/// What closing the sheet asked for.
///
/// A value rather than navigation performed inside the sheet: the sheet does
/// not know what "go to course" means on the screen that opened it, and pushing
/// a route from under a closing modal is how a navigator ends up with an orphan.
@freezed
sealed class _CoachSheetResult with _$CoachSheetResult {
  const factory _CoachSheetResult.close() = _CoachSheetClose;
  const factory _CoachSheetResult.openCourse(String courseId) = _CoachSheetOpenCourse;
}

/// Opens the Coach sheet and settles what the reader chose on the way out.
///
/// Returns the course id when they asked for one, so the CALLER navigates —
/// after the modal is gone.
Future<String?> showCoachSheet(
  BuildContext context, {
  required CoachEntry entry,
  String? lessonId,
  String? habitId,
}) async {
  final cubit = AppDI.injector.get<CoachCubit>();

  /// The device's real safe-area insets, read HERE and carried inside.
  ///
  /// `showModalBottomSheet` strips the top padding from the MediaQuery it hands
  /// its child — reasonable for a sheet that stops short of the top, wrong for
  /// this one, which is full-bleed by design. Without this the header renders
  /// under the clock and the notch, which is exactly how it first shipped to
  /// the simulator.
  final insets = MediaQuery.viewPaddingOf(context);

  final result = await showModalBottomSheet<_CoachSheetResult>(
    context: context,
    // Full-bleed, as drawn: the design's sheet is `inset: 0`, not a card that
    // leaves the page showing behind it. A conversation about something
    // difficult should not have the app peeking round its edges.
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    constraints: const BoxConstraints.expand(),
    builder: (sheetContext) => MediaQuery(
      data: MediaQuery.of(sheetContext).copyWith(
        padding: insets,
        viewPadding: insets,
      ),
      child: BlocProvider.value(
        value: cubit,
        child: _CoachSheet(entry: entry, lessonId: lessonId, habitId: habitId),
      ),
    ),
  );

  // End the session ONLY when the reader chose to end it. A swipe-away, a
  // phone call or a backgrounded app is not "I'm done" — and treating it as
  // one threw the whole conversation away for a stray gesture. The server
  // resumes an ACTIVE session next time the sheet opens.
  if (result != null) await cubit.endSession();

  return switch (result) {
    _CoachSheetOpenCourse(courseId: final id) => id,
    _ => null,
  };
}

class _CoachSheet extends StatefulWidget {
  final CoachEntry entry;
  final String? lessonId;
  final String? habitId;

  const _CoachSheet({required this.entry, this.lessonId, this.habitId});

  @override
  State<_CoachSheet> createState() => _CoachSheetState();
}

class _CoachSheetState extends State<_CoachSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    final cubit = context.read<CoachCubit>();
    // The cubit resolves fixed lines through this rather than importing
    // `context.l10n` itself, so the same cubit can be driven with no widget
    // tree at all.
    cubit.promptResolver = (key, args) => coachPrompt(context, key, args) ?? '';
    cubit.open(
      entry: widget.entry,
      locale: LocaleSettings.currentLocale.languageCode,
      lessonId: widget.lessonId,
      habitId: widget.habitId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CoachCubit, CoachState>(
      listenWhen: (prev, curr) => prev.silent != curr.silent,
      listener: (context, state) {
        // A door that decided to stay quiet is not an error and gets no
        // message — the sheet simply goes away again. Every other ending
        // keeps its one button: "Đóng · về chỗ vừa rời đi".
        if (state.silent) Navigator.of(context).pop(const _CoachSheetResult.close());
      },
      builder: (context, state) {
        final cubit = context.read<CoachCubit>();
        final isSafety = state.ui.kind == CoachUiKind.safety;

        return Material(
          color: CoachStyle.sheetBackground,
          // The sheet is pinned to the full screen (BoxConstraints.expand), so it
          // does NOT shrink when the keyboard opens — the composer would sit under
          // it, which is exactly what shipped to the simulator first: messages
          // visible, nothing to type into. Inset the content by the keyboard.
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
            child: Column(
              children: [
                _Header(
                  // "đang trả lời…" while a turn is in flight, else the step.
                  subtitle: state.typing ? context.l10n.coach.stepWait : coachStepLabel(context, state.step),
                  // The avatar acts the step out: listening while the reader
                  // types, thinking while composing or at the two columns,
                  // gentle on the safety screen. Same selector as the design's.
                  mood: coachSlimeMoodFor(
                    step: state.step,
                    typing: state.typing,
                    safety: isSafety,
                  ),
                  onClose: () => Navigator.of(context).pop(const _CoachSheetResult.close()),
                ),
                // Thanh habit — a floating pill under the header, from the
                // moment the habit is certain to the end of the session. Not a
                // step of the flow and never a line of dialogue: a status bar
                // with the reader's own way out of a wrong guess.
                if (!isSafety && state.ui.habit != null)
                  _HabitChip(
                    title: state.ui.habit!.title,
                    onChange: state.status == CoachStatus.sending
                        ? null
                        : () => cubit.changeHabit(context.l10n.coach.habitChipChangeEcho),
                  ),
                Expanded(
                  child: switch (state.status) {
                    CoachStatus.opening => const Center(child: CircularProgressIndicator()),
                    CoachStatus.failed => _Failed(onRetry: _start),
                    _ when isSafety => CoachSafetyPanel(hotlines: state.ui.hotlines),
                    _ => CoachMessageList(
                      messages: state.messages,
                      typing: state.typing,
                      // The card stays on screen through LEAVE, under the
                      // Coach's "Mình mở khoá đó cho bạn."
                      course: state.ui.kind == CoachUiKind.courseCard || state.step == 'leave' ? state.ui.course : null,
                      // Tap on the card = "Học ngay": straight to the course,
                      // and the session ends on the spot.
                      onCourseTap: state.ui.kind != CoachUiKind.courseCard || state.status == CoachStatus.sending
                          ? null
                          : () => _openCourse(context, cubit),
                      onCourseSave: state.ui.kind != CoachUiKind.courseCard || state.status == CoachStatus.sending
                          ? null
                          : () => cubit.courseAction('save', label: context.l10n.coach.courseCardSaveEcho),
                      onCourseClose: state.ui.kind != CoachUiKind.courseCard || state.status == CoachStatus.sending
                          ? null
                          : () => cubit.courseAction('close', label: context.l10n.coach.courseCardCloseEcho),
                      // ⟨Phương án⟩ in the thread, as the design draws them —
                      // and the closing choice is drawn the same way.
                      options: (state.ui.kind == CoachUiKind.chips || state.ui.kind == CoachUiKind.nextSession) && !state.typing
                          ? _OptionPills(state: state, cubit: cubit, busy: state.status == CoachStatus.sending)
                          : null,
                      draft: state.ui.kind == CoachUiKind.twoCols
                          ? CoachTwoColumns(
                              left: state.columnLeft,
                              right: state.columnRight,
                              onMove: (index, {required fromRight}) => cubit.moveLine(index, fromRight: fromRight),
                              onEdit: (index, {required inRight, required text}) => cubit.editLine(index, inRight: inRight, text: text),
                              onDelete: (index, {required inRight}) => cubit.deleteLine(index, inRight: inRight),
                            )
                          : null,
                    ),
                  },
                ),
                if (!isSafety && (state.status == CoachStatus.ready || state.status == CoachStatus.sending)) CoachComposer(state: state, cubit: cubit),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// "Học ngay", from the card body or its button: send the open event, then —
/// the session having ended server-side — leave the sheet FOR the course.
/// Nothing else stands between the tap and the Roadmap.
Future<void> _openCourse(BuildContext context, CoachCubit cubit) async {
  final course = cubit.state.ui.course;
  if (course == null) return;

  await cubit.courseAction('open', label: context.l10n.coach.courseOpenEcho);
  if (context.mounted && cubit.state.ended) {
    Navigator.of(context).pop(_CoachSheetResult.openCourse(course.courseId));
  }
}

/// The habit chip: "Đang nói về · Nói ra ý mình · ⇄".
///
/// Centred, floating on a shadow, exactly as the design draws it. The swap
/// button is the reader's right — "không bao giờ được ẩn theo điều kiện" — so it
/// is only ever disabled while a turn is in flight, never hidden.
class _HabitChip extends StatelessWidget {
  final String title;
  final VoidCallback? onChange;

  const _HabitChip({required this.title, this.onChange});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.coach;

    return Padding(
      padding: EdgeInsets.fromLTRB(15.w, 12.h, 15.w, 8.h),
      child: Center(
        child: Container(
          padding: EdgeInsets.fromLTRB(15.w, 5.h, 5.w, 5.h),
          decoration: BoxDecoration(
            color: CoachStyle.surface,
            border: Border.all(color: CoachStyle.border),
            borderRadius: BorderRadius.circular(99.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0x1F0D121C),
                blurRadius: 16.r,
                offset: Offset(0, 6.h),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.habitChipLead,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: CoachStyle.textMuted,
                ),
              ),
              SizedBox(width: 9.w),
              // The title is data, read from the DB — "không rút gọn, không
              // diễn đạt lại" — so it is allowed to take the room it needs and
              // ellipsis only at the edge of the screen.
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: CoachStyle.textPrimary,
                  ),
                ),
              ),
              SizedBox(width: 9.w),
              Semantics(
                button: true,
                label: l10n.habitChipChange,
                child: GestureDetector(
                  onTap: onChange,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 28.w,
                    height: 28.w,
                    decoration: BoxDecoration(
                      color: CoachStyle.sampleBackground,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.swap_horiz_rounded,
                      size: 16.w,
                      color: const Color(0xFF5B54A8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// White bar, hairline underneath, the Coach on the left, "Đóng" on the right.
///
/// Two lines, as drawn: the name, and under it what this moment of the
/// conversation is — "mood đầu ngày · 5 mức, 1 chạm". No other control: the
/// design's header has no voice picker and no settings, because a header full
/// of controls is a screen, and this is a conversation.
class _Header extends StatelessWidget {
  final String? subtitle;
  final CoachSlimeMood mood;
  final VoidCallback onClose;

  const _Header({
    required this.subtitle,
    required this.mood,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // The drawing's 56px top was measured on a 47pt status bar, so the rule
      // is "inset + 9" rather than a constant — a Dynamic Island phone needs
      // more, and an older one less.
      padding: EdgeInsets.fromLTRB(
        16.w,
        MediaQuery.viewPaddingOf(context).top + 9.h,
        16.w,
        12.h,
      ),
      decoration: const BoxDecoration(
        color: CoachStyle.surface,
        border: Border(bottom: BorderSide(color: CoachStyle.border)),
      ),
      child: Row(
        children: [
          CoachSlime(mood: mood, size: 34),
          SizedBox(width: 11.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        context.l10n.coach.sheetTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w700,
                          color: CoachStyle.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    // The design's stage marker — a literal, the same word in
                    // every locale, so it is not a slang key.
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: CoachStyle.selectedBackground,
                        border: Border.all(color: CoachStyle.selectedBorderSoft),
                        borderRadius: BorderRadius.circular(99.r),
                      ),
                      child: Text(
                        'BETA',
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: CoachStyle.userBubble,
                        ),
                      ),
                    ),
                  ],
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w600,
                      color: CoachStyle.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 28.h,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CoachStyle.sampleBackground,
                borderRadius: BorderRadius.circular(99.r),
              ),
              child: Text(
                context.l10n.coach.close,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: CoachStyle.textChip,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  final VoidCallback onRetry;

  const _Failed({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.coach.failedTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
                height: 1.55,
                color: CoachStyle.textBody,
              ),
            ),
            SizedBox(height: 14.h),
            GestureDetector(
              onTap: onRetry,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 11.h),
                decoration: BoxDecoration(
                  color: CoachStyle.chipBackground,
                  border: Border.all(color: CoachStyle.border, width: 1.5),
                  borderRadius: BorderRadius.circular(99.r),
                ),
                child: Text(
                  context.l10n.coach.retry,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: CoachStyle.textChip,
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
