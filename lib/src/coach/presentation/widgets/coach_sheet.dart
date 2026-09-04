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
  /// Luồng 2 — ⟨Học tiếp⟩: the sheet is done and the reader goes on to the next keypoint.
  const factory _CoachSheetResult.nextKeypoint() = _CoachSheetNextKeypoint;
}

/// Luồng 2/3 — what the keypoint page does after the sheet: open a course, go
/// on to the next keypoint, or nothing.
class CoachSheetOutcome {
  final String? courseId;
  final bool nextKeypoint;

  const CoachSheetOutcome({this.courseId, this.nextKeypoint = false});
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
  final outcome = await showCoachSheetForKeypoint(context, entry: entry, lessonId: lessonId, habitId: habitId);

  return outcome.courseId;
}

/// Luồng 2/3 — the sheet opened from the keypoint invite: it may end on "go to
/// the next keypoint" as well as on a course, so the whole outcome comes back.
Future<CoachSheetOutcome> showCoachSheetForKeypoint(
  BuildContext context, {
  required CoachEntry entry,
  String? lessonId,
  String? habitId,
  String? keypointId,
  String? courseId,
  bool recap = false,
  List<QuestionEntity> quizQuestions = const [],
  String quizTitle = '',
}) async {
  final cubit = AppDI.injector.get<CoachCubit>();
  cubit.quizQuestions = quizQuestions;
  cubit.quizTitle = quizTitle;

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
    // A downward swipe used to close the whole sheet — reaching for the thread
    // and losing the conversation instead (bug sheet 2026-08-28 16:18: "vuốt
    // xuống là tắt màn hình AI Coach"). The sheet is full-bleed, so the gesture
    // overlaps ordinary scrolling everywhere; leaving is the header's ✕.
    enableDrag: false,
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
        child: _CoachSheet(
          entry: entry,
          lessonId: lessonId,
          habitId: habitId,
          keypointId: keypointId,
          courseId: courseId,
          recap: recap,
        ),
      ),
    ),
  );

  // End the session ONLY when the reader chose to end it. A swipe-away, a
  // phone call or a backgrounded app is not "I'm done" — and treating it as
  // one threw the whole conversation away for a stray gesture. The server
  // resumes an ACTIVE session next time the sheet opens.
  if (result != null) await cubit.endSession();

  return switch (result) {
    _CoachSheetOpenCourse(courseId: final id) => CoachSheetOutcome(courseId: id),
    _CoachSheetNextKeypoint() => const CoachSheetOutcome(nextKeypoint: true),
    _ => const CoachSheetOutcome(),
  };
}

class _CoachSheet extends StatefulWidget {
  final CoachEntry entry;
  final String? lessonId;
  final String? habitId;
  final String? keypointId;
  final String? courseId;
  final bool recap;

  const _CoachSheet({
    required this.entry,
    this.lessonId,
    this.habitId,
    this.keypointId,
    this.courseId,
    this.recap = false,
  });

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
      keypointId: widget.keypointId,
      courseId: widget.courseId,
      recap: widget.recap,
    );
  }

  /// Luồng 2 — the server said `runQuiz`: the keypoint quiz runs on its own
  /// screen (the same deck the Practice Hub opens) and reports back. Launched
  /// once per step; leaving the deck early reports the answers checked so far.
  bool _quizLaunched = false;

  Future<void> _runQuiz(BuildContext context, CoachCubit cubit) async {
    final answers = await KeypointQuizPage.push(
      context,
      title: cubit.quizTitle,
      questions: cubit.quizQuestions,
    );
    if (!context.mounted) return;
    await cubit.sendQuizDone(answers ?? const []);
  }

  /// Luồng 6 — ⟨Đóng⟩ mid-session asks ONCE to stay, then respects the answer.
  ///
  /// The plea appears only when there is something to finish (the reader has
  /// spoken, the session is live, the step has a line for it) and only while
  /// the server still allows it — two sessions closed against the plea and it
  /// is gone for good. A barrier tap is not a decision: nothing is recorded and
  /// the sheet stays.
  Future<void> _requestClose(BuildContext context, CoachState state, CoachCubit cubit) async {
    final line = _exitPleaLineFor(context, state);
    final canPlead =
        state.exitPlea &&
        !state.ended &&
        state.status == CoachStatus.ready &&
        line != null &&
        state.messages.any((m) => !m.isCoach);

    if (canPlead) {
      final decision = await CoachExitPleaSheet.show(context, line);
      if (decision == CoachExitDecision.stay) {
        unawaited(cubit.recordExit(stayed: true));

        return;
      }
      if (decision == null) return;
      unawaited(cubit.recordExit(stayed: false));
    }

    if (!context.mounted) return;
    Navigator.of(context).pop(const _CoachSheetResult.close());
  }

  /// The four written pleas, by where the reader is; null where none fits —
  /// a hub, a card, a finished session.
  String? _exitPleaLineFor(BuildContext context, CoachState state) {
    final l10n = context.l10n.coach;
    const story = {'story', 'storyTalk', 'depth', 'checkinTell', 'tell', 'tell2'};
    const scene = {'tellOnce', 'sceneRetry', 'sceneFix', 'sceneStage2', 'sceneMet', 'sceneDid', 'sceneChange'};

    if (story.contains(state.step)) return l10n.exitPleaStory;
    if (scene.contains(state.step)) return l10n.exitPleaScene;
    if (state.step == 'quizInChat') {
      return l10n.exitPleaQuiz(n: (state.ui.quizRemaining ?? 2).toString());
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CoachCubit, CoachState>(
      listenWhen: (prev, curr) =>
          prev.silent != curr.silent ||
          prev.step != curr.step ||
          prev.ui.action != curr.ui.action ||
          prev.ended != curr.ended,
      listener: (context, state) {
        // Luồng 2 — the two things the app DOES on the server's word.
        if (state.step != 'quizRun') _quizLaunched = false;
        if (state.ui.action == 'runQuiz' && state.step == 'quizRun' && !_quizLaunched) {
          _quizLaunched = true;
          _runQuiz(context, context.read<CoachCubit>());
        }
        if (state.ended && state.ui.action == 'nextKeypoint') {
          Navigator.of(context).pop(const _CoachSheetResult.nextKeypoint());

          return;
        }
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
                  // The avatar acts the step out: listening while the reader
                  // types, thinking while composing or at the two columns,
                  // gentle on the safety screen. Same selector as the design's.
                  mood: coachSlimeMoodFor(
                    step: state.step,
                    typing: state.typing,
                    safety: isSafety,
                  ),
                  onClose: () {
                    _requestClose(context, state, cubit);
                  },
                ),
                // Thanh habit — a floating pill under the header, from the
                // moment the habit is certain to the end of the session. Not a
                // step of the flow and never a line of dialogue: a status bar
                // with the reader's own way out of a wrong guess.
                if (!isSafety && state.ui.habit != null)
                  _HabitChip(
                    title: state.ui.habit!.title,
                    // Luồng 5 — "⟨Đổi habit⟩ bị ẩn": the reader opened THIS
                    // habit's own screen; the one place the never-hide rule
                    // is turned over, on purpose.
                    canChange: state.entry != CoachEntry.habit,
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
  LogDev.data('[CoachDbg] _openCourse tap: course=${course?.courseId} step=${cubit.state.step} kind=${cubit.state.ui.kind}'); // TEMP-DEBUG
  if (course == null) return;

  await cubit.courseAction('open', label: context.l10n.coach.courseOpenEcho);
  LogDev.data('[CoachDbg] after open: ended=${cubit.state.ended} status=${cubit.state.status} mounted=${context.mounted}'); // TEMP-DEBUG
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
  /// False hides the ⇄ button entirely (luồng 5, the Habit door).
  final bool canChange;

  const _HabitChip({required this.title, this.onChange, this.canChange = true});

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
              if (canChange) ...[
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
            ],
          ),
        ),
      ),
    );
  }
}

/// White bar, hairline underneath, the Coach on the left, "Đóng" on the right.
///
/// ONE line: the name. The step label that used to sit under it is gone
/// (owner's call, 2026-08-28) — naming the step turned a conversation into a
/// form the reader could see the length of. No other control either: the
/// design's header has no voice picker and no settings, because a header full
/// of controls is a screen, and this is a conversation.
class _Header extends StatelessWidget {
  final CoachSlimeMood mood;
  final VoidCallback onClose;

  const _Header({
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
            child: Row(
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
