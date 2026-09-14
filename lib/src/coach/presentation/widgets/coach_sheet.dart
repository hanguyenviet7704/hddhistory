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

  /// The talk ran to its end and the reader chose the Roadmap.
  ///
  /// Named `nextKeypoint` until 2026-09-05, when it had long since stopped
  /// meaning that — it mapped to [CoachSheetOutcome.toRoadmap]. Keeping the
  /// wrong name was survivable while it was the only exit; it stops being
  /// survivable now that a REAL next-keypoint exit sits beside it.
  const factory _CoachSheetResult.roadmap() = _CoachSheetRoadmap;

  /// The reader chose to go straight on to the next keypoint.
  const factory _CoachSheetResult.nextKeypoint() = _CoachSheetNextKeypoint;
}

/// Luồng 2/3 — what the keypoint page does after the sheet: open a course,
/// leave for the Roadmap, or nothing.
class CoachSheetOutcome {
  final String? courseId;

  /// The talk finished on its own terms. The button that sent us here reads
  /// "Đóng · về Roadmap", so that is where the reader goes.
  final bool toRoadmap;

  /// They asked for the next keypoint outright — the second button at the end
  /// of a session opened from a keypoint that is not the course's last.
  final bool nextKeypoint;

  /// Cuộc trò chuyện đã đi HẾT, chứ không phải bị đóng giữa chừng.
  ///
  /// Hai màn mời đều chạy một vòng lặp "đóng sheet thì mời lại", vì backing out
  /// của sheet không phải là quyết định đi tiếp. Nhưng LÀM XONG thì là một
  /// quyết định — mời lại người vừa luyện hết tình huống là bắt họ làm lại từ
  /// đầu (owner on-device 2026-09-09: "tập hết tình huống sau đó bấm đóng thì
  /// về tiếp màn này"). Cờ này để vòng lặp phân biệt được hai việc đó.
  final bool ended;

  const CoachSheetOutcome({
    this.courseId,
    this.toRoadmap = false,
    this.nextKeypoint = false,
    this.ended = false,
  });
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
  bool hasNextKeypoint = false,
  bool hasRoadmap = false,
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
  ///
  /// Read from the VIEW, not from this context: the Habit tab wraps its page
  /// in a SafeArea, so by the time the bubble calls in, the MediaQuery here
  /// already has its top padding consumed and reports 0 — which put the header
  /// back under the clock on that tab only (owner, 2026-09-04).
  final view = View.of(context);
  final fromView = EdgeInsets.fromViewPadding(view.viewPadding, view.devicePixelRatio);
  final fromContext = MediaQuery.viewPaddingOf(context);
  final insets = EdgeInsets.only(
    top: math.max(fromView.top, fromContext.top),
    bottom: math.max(fromView.bottom, fromContext.bottom),
    left: math.max(fromView.left, fromContext.left),
    right: math.max(fromView.right, fromContext.right),
  );

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
          hasNextKeypoint: hasNextKeypoint,
          hasRoadmap: hasRoadmap,
        ),
      ),
    ),
  );

  // End the session ONLY when the reader chose to END it — which ⟨Đóng⟩ is
  // not (owner 2026-09-05: "nhiều lúc bấm đóng bị thoát luôn coach").
  //
  // Closing the sheet is putting the phone down, not finishing. The session
  // stays ACTIVE so the next open carries on where they were; the server
  // resumes an active session by design. A swipe-away, a phone call or a
  // backgrounded app never ended it either, for the same reason.
  //
  // These DO end it: a course opened, the Roadmap, the next keypoint — each is
  // the reader leaving for somewhere else — and a session the server has
  // already closed, where ⟨Đóng⟩ is just acknowledging the end.
  // Đọc TRƯỚC `endSession()` — sau đó cờ này không còn nói được gì về việc
  // cuộc trò chuyện có đi hết hay không.
  final talkEnded = cubit.state.ended;

  final endsSession = switch (result) {
    null => false,
    _CoachSheetClose() => talkEnded,
    _ => true,
  };
  if (endsSession) await cubit.endSession();

  return switch (result) {
    _CoachSheetOpenCourse(courseId: final id) => CoachSheetOutcome(courseId: id, ended: talkEnded),
    _CoachSheetRoadmap() => CoachSheetOutcome(toRoadmap: true, ended: talkEnded),
    _CoachSheetNextKeypoint() => CoachSheetOutcome(nextKeypoint: true, ended: talkEnded),
    _ => CoachSheetOutcome(ended: talkEnded),
  };
}

class _CoachSheet extends StatefulWidget {
  final CoachEntry entry;
  final String? lessonId;
  final String? habitId;
  final String? keypointId;
  final String? courseId;
  final bool recap;

  /// Whether the course has a keypoint after this one — decided by the page
  /// that opened the sheet, which is the only place that knows. False on the
  /// course's last keypoint, and the end of the session then offers the
  /// Roadmap alone.
  final bool hasNextKeypoint;

  /// Có roadmap nào để về hay không — trang mở sheet là nơi DUY NHẤT biết, y
  /// như `hasNextKeypoint`.
  ///
  /// Thiếu nó thì nút cuối phiên nói "về Roadmap" ở cả những cửa không có khoá
  /// nào phía sau (cửa "vừa thêm thói quen" đi từ trang habit), bấm vào không
  /// đi đâu được, và trang mời lại hiện lên (owner on-device 2026-09-09).
  final bool hasRoadmap;

  const _CoachSheet({
    required this.entry,
    this.lessonId,
    this.habitId,
    this.keypointId,
    this.courseId,
    this.recap = false,
    this.hasNextKeypoint = false,
    this.hasRoadmap = false,
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
    //
    // KHÔNG bám vào context của sheet này. Cubit là singleton và một lượt trả
    // về có thể hạ cánh sau khi sheet đã đóng — lúc đó `context` của State ném
    // "This widget has been unmounted, so the State no longer has a context",
    // giữa `_applyTurn`, nên lượt ấy hỏng nửa chừng (đã thấy trong log máy
    // này 2026-09-09 14:17, và bay lên Crashlytics). Context của app sống lâu
    // hơn sheet và tra được đúng bản dịch đó.
    cubit.promptResolver = (key, args) {
      final resolverContext = mounted ? context : AppConfig.instance.context;

      return resolverContext == null ? '' : coachPrompt(resolverContext, key, args) ?? '';
    };
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

  /// Analytics — bề mặt đã đếm rồi.
  ///
  /// `ui.kind` là thứ quyết định người đọc đang NHÌN thấy gì (thẻ khoá học,
  /// bảng điểm, màn an toàn, toast đánh giá), nên một lần đổi kind là một lần
  /// hiện. Giữ lại ở đây vì listener không được đưa state cũ.
  CoachUiKind? _lastKind;

  Future<void> _runQuiz(BuildContext context, CoachCubit cubit) async {
    final answers = await KeypointQuizPage.push(
      context,
      title: cubit.quizTitle,
      questions: cubit.quizQuestions,
    );
    if (!context.mounted) return;
    await cubit.sendQuizDone(answers ?? const []);
  }

  /// Luồng 6 — ⟨Đóng⟩ giữa phiên: níu trước, rồi mới hỏi vừa rồi thế nào.
  ///
  /// Hai sheet NỐI TIẾP nhau, đúng thứ tự design vẽ (`EXIT_PLEA` → `RATE_COACH`,
  /// 2026-09-14): bấm ⟨Đóng⟩ thì Coach níu một câu; chọn ⟨Ở lại một câu⟩ là
  /// xong, chọn ⟨Vẫn đóng⟩ thì mới hiện popup đánh giá.
  ///
  /// Trước đây hai cái này GIÀNH lượt nhau — ai chưa feedback thì hỏi lý do, ai
  /// feedback rồi thì níu — nên người mới dùng không bao giờ được níu, còn người
  /// đã trả lời một lần thì không bao giờ được hỏi lại. Nối tiếp bỏ cả hai chỗ
  /// hụt đó.
  ///
  /// Cái giữ popup khỏi thành phiền là `state.exitFeedback`: server tính theo
  /// các knob tần suất bên admin, client chỉ đọc.
  Future<void> _requestClose(BuildContext context, CoachState state, CoachCubit cubit) async {
    // Chỉ còn MỘT câu hỏi, và luôn là lời níu (owner 2026-09-09: "bấm đóng là
    // luôn luôn níu — ở lại một câu").
    //
    // Ba chốt cũ đã bỏ theo chữ "luôn luôn": bảng hỏi lý do thoát không còn
    // giành lượt (`state.exitFeedback`), trần hai lần "Vẫn đóng" của server
    // không còn tắt lời níu (`state.exitPlea`), và bước nào không có câu níu
    // riêng thì dùng câu chung thay vì im lặng đóng luôn.
    //
    // Cái duy nhất giữ lại: nói HẾT rồi thì không níu. Lúc đó ✕ chỉ là gật đầu
    // với một phiên đã xong, và "ở lại một câu" là một lời nói dối — không còn
    // câu nào phía sau để ở lại.
    final live = !state.ended && state.status == CoachStatus.ready;

    if (live) {
      final line = _exitPleaLineFor(context, state) ?? context.l10n.coach.exitPleaGeneric;
      CoachTracking.exitPleaView(state);
      final decision = await CoachExitPleaSheet.show(context, line);
      if (decision == CoachExitDecision.stay) {
        unawaited(cubit.recordExit(stayed: true));

        return;
      }
      // A barrier tap is not a decision: nothing is recorded and the sheet
      // stays.
      if (decision == null) return;

      // ⟨Vẫn đóng⟩ → popup đánh giá, nếu tần suất bên admin cho phép lần này.
      CoachExitFeedback? feedback;
      if (state.exitFeedback && context.mounted) {
        // Loại lấy từ state, tức từ server — client không tự suy ra bộ chip,
        // nếu không thì hàng ghi về sẽ không khớp với câu đã thật sự hỏi.
        feedback = await CoachExitFeedbackSheet.show(context, kind: state.sessionKind);
      }
      // Trả lời hay ⟨Để sau⟩ đều ghi: server cần đếm cả hai để biết "không ai
      // chê" khác "không ai buồn trả lời".
      unawaited(
        cubit.recordExit(
          stayed: false,
          chips: feedback?.chips,
          note: feedback?.note.isEmpty ?? true ? null : feedback!.note,
        ),
      );
    }

    if (!context.mounted) return;
    Navigator.of(context).pop(const _CoachSheetResult.close());
  }

  /// The written pleas, by where the reader is. Null means "no line of its
  /// own" — a hub, a card — and the caller falls back to the generic one
  /// rather than letting the ✕ through unasked.
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

  /// Bốn bề mặt đáng đếm riêng — phần còn lại của phiên đã nằm trong
  /// `coach_turn_send` với `step` của nó, đếm thêm chỉ là nhân đôi.
  void _trackSurface(CoachState state) {
    if (state.ui.kind == _lastKind) return;
    _lastKind = state.ui.kind;

    switch (state.ui.kind) {
      case CoachUiKind.courseCard:
        CoachTracking.courseCardView(state);
      case CoachUiKind.rating:
        CoachTracking.ratingView(state);
      case CoachUiKind.safety:
        CoachTracking.safetyView(state);
      case CoachUiKind.sceneScore:
        CoachTracking.sceneScoreView(state);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CoachCubit, CoachState>(
      listenWhen: (prev, curr) =>
          prev.silent != curr.silent || prev.step != curr.step || prev.ui.action != curr.ui.action || prev.ended != curr.ended || prev.ui.kind != curr.ui.kind,
      listener: (context, state) {
        _trackSurface(state);
        // Luồng 2 — the two things the app DOES on the server's word.
        if (state.step != 'quizRun') _quizLaunched = false;
        if (state.ui.action == 'runQuiz' && state.step == 'quizRun' && !_quizLaunched) {
          _quizLaunched = true;
          CoachTracking.quizRun(state, questionCount: context.read<CoachCubit>().quizQuestions.length);
          _runQuiz(context, context.read<CoachCubit>());
        }
        // Owner 2026-09-05: the sheet no longer closes ITSELF when the talk
        // ends. It used to pop the moment `nextKeypoint` arrived — which is the
        // same turn the grading is drawn on — so the reader was thrown out of
        // the page before they could read what they had got right ("trả lời
        // xong là bị out luôn"). The server now sends `keypointDone`, the
        // closing line says where to go, and the reader leaves by the button.

        // A door that decided to stay quiet is not an error and gets no
        // message — the sheet simply goes away again. Every other ending keeps
        // its one button.
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
                // Luồng 1 — "Câu 3/8" and ⟨Bỏ qua⟩ while the onboarding runs.
                // The one place the sheet may count its steps: these are
                // questions, not the conversation, and the reader should see
                // how few there are. Hidden at the intro, where the only thing
                // to do is ⟨Bắt đầu⟩.
                if (!isSafety && state.ui.onboard != null && state.ui.onboard!.step > 0)
                  _OnboardStrip(
                    step: state.ui.onboard!.step,
                    total: state.ui.onboard!.total,
                    onSkip: state.ui.onboard!.skippable && state.status != CoachStatus.sending ? () => cubit.pick('skip', context.l10n.coach.onboardSkipEcho) : null,
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
                    onChange: state.status == CoachStatus.sending ? null : () => cubit.changeHabit(context.l10n.coach.habitChipChangeEcho),
                  ),
                // Luồng 2/3 — cùng thanh đó, phạm vi là keypoint hoặc cả khoá.
                // KHÔNG có nút đổi: keypoint vừa học xong không chọn lại được.
                if (!isSafety && state.ui.habit == null && state.ui.scope != null)
                  _HabitChip(
                    title:
                        '${state.ui.scope!.kind == 'course' ? context.l10n.coach.scopeCourse : context.l10n.coach.scopeKeypoint}'
                        ' · ${state.ui.scope!.title}',
                    canChange: false,
                    maxLines: 2,
                  ),
                Expanded(
                  child: switch (state.status) {
                    // Chấm "đang gõ" của chính Coach, không phải vòng xoay
                    // giữa màn trắng (owner 2026-09-09: "có cách nào để bớt
                    // xoay không"). Cùng một thời gian chờ, nhưng nó đọc ra là
                    // Coach đang soạn câu chứ không phải app bị treo — và khi
                    // lượt đầu về, `didUpdateWidget` thấy danh sách rỗng chuyển
                    // sang có bài nên vẫn `_settleToEnd()` xuống đáy như cũ.
                    CoachStatus.opening => CoachMessageList(messages: state.messages, typing: true),
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
                      onCourseTap: state.ui.kind != CoachUiKind.courseCard || state.status == CoachStatus.sending ? null : () => _openCourse(context, cubit),
                      onCourseSave: state.ui.kind != CoachUiKind.courseCard || state.status == CoachStatus.sending
                          ? null
                          : () => cubit.courseAction('save', label: context.l10n.coach.courseCardSaveEcho),
                      onCourseClose: state.ui.kind != CoachUiKind.courseCard || state.status == CoachStatus.sending
                          ? null
                          : () => cubit.courseAction('close', label: context.l10n.coach.courseCardCloseEcho),
                      // The alternative to the course: another scene about the
                      // same habit, one rung up. Rides the same `course` event
                      // — the card is where the two ways forward sit together,
                      // so the reader is choosing between them, not doing two
                      // things.
                      onCourseHarder: state.ui.kind != CoachUiKind.courseCard || state.status == CoachStatus.sending
                          ? null
                          : () => cubit.courseAction('harder', label: context.l10n.coach.courseHarderSceneEcho),
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
                if (!isSafety && (state.status == CoachStatus.ready || state.status == CoachStatus.sending)) CoachComposer(state: state, cubit: cubit, hasNextKeypoint: widget.hasNextKeypoint, hasRoadmap: widget.hasRoadmap),
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
/// Luồng 1 — the onboarding's progress: a thin bar, "Câu n/N", and ⟨Bỏ qua⟩
/// where the question allows it (the address does not — it is what every
/// later line is written with).
class _OnboardStrip extends StatelessWidget {
  final int step;
  final int total;
  final VoidCallback? onSkip;

  const _OnboardStrip({required this.step, required this.total, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.coach;

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 8.w, 6.h),
      color: CoachStyle.surface,
      child: Row(
        children: [
          Text(
            l10n.onboardProgress(n: step.toString(), total: total.toString()),
            style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: CoachStyle.textChip),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99.r),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : (step / total).clamp(0.0, 1.0),
                minHeight: 4.h,
                backgroundColor: CoachStyle.selectedBorderSoft,
                valueColor: const AlwaysStoppedAnimation<Color>(CoachStyle.userBubble),
              ),
            ),
          ),
          SizedBox(width: 4.w),
          // Keeps its width when hidden so the bar does not jump between steps.
          Opacity(
            opacity: onSkip == null ? 0 : 1,
            child: IgnorePointer(
              ignoring: onSkip == null,
              child: TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: CoachStyle.textMuted,
                ),
                child: Text(
                  l10n.onboardSkip,
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitChip extends StatelessWidget {
  final String title;
  final VoidCallback? onChange;

  /// False hides the ⇄ button entirely (luồng 5, the Habit door).
  final bool canChange;

  /// Số dòng tối đa cho tiêu đề.
  ///
  /// Tên habit ngắn nên một dòng là đủ, còn phạm vi của luồng 2 là tiêu đề
  /// keypoint — dài, và cắt bằng "…" thì không còn đọc được đang bàn bài nào
  /// (owner bắt trên sim 2026-09-04).
  final int maxLines;

  const _HabitChip({
    required this.title,
    this.onChange,
    this.canChange = true,
    this.maxLines = 1,
  });

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
                  maxLines: maxLines,
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
