part of '../../lesson.dart';

/// Practice quiz for ONE keypoint: a vertically-swiped deck of that keypoint's
/// own exercises (design "3 · Learning" → Practice / Quiz — question deck, the
/// `_Keypoint Swipe Lab` in `mode="quiz"`).
///
/// Practice hangs off the keypoint: the questions come straight from the
/// keypoint's `type: exercise` learning items, the same items the server
/// derives a habit's practice from. Opened from the keypoint deck's terminal
/// peek card ([KeypointDoneCard]).
///
/// Same deck mechanics as [HabitQuizPage] — one card per question plus a
/// terminal done card, forward reveal gated on grading, swipe back always free —
/// with the question rendering shared through [QuizQuestionCard]. What is
/// deliberately DIFFERENT: nothing is submitted anywhere. The keypoint was
/// already completed by reading it, there is no attempt endpoint for keypoint
/// practice, and filing it as lesson progress would overwrite the read
/// completion with quiz scores nobody asked to be graded on.
class KeypointQuizPage extends StatefulWidget {
  final String title;
  final List<QuestionEntity> questions;

  const KeypointQuizPage({super.key, required this.title, required this.questions});

  /// Pushed imperatively rather than through a typed go_router route because it
  /// carries entities, and the repo has no `$extra` typed routes to follow.
  /// Resolves with the deck's answers as checked so far — the AI Coach (luồng
  /// 2) reads them to talk about the CONTENT of what went wrong. The Practice
  /// Hub ignores the value.
  static Future<List<QuizCardAnswer>?> push(
    BuildContext context, {
    required String title,
    required List<QuestionEntity> questions,
  }) {
    return Navigator.of(context).push<List<QuizCardAnswer>>(
      MaterialPageRoute(builder: (_) => KeypointQuizPage(title: title, questions: questions)),
    );
  }

  @override
  State<KeypointQuizPage> createState() => _KeypointQuizPageState();
}

class _KeypointQuizPageState extends State<KeypointQuizPage> {
  late final PageController _pageController = PageController();
  late final List<QuizCardAnswer> _answers;

  /// Index of the card on screen, and the furthest one revealed so far. They
  /// differ whenever the reader has swiped back to review.
  int _index = 0;
  int _furthest = 0;

  /// The summary card's view is reported once per quiz run, however many
  /// times the reader swipes back and forth over it.
  bool _completeViewTracked = false;

  @override
  void initState() {
    super.initState();
    _answers = widget.questions.where(QuizCardAnswer.isPlayableQuestion).map(QuizCardAnswer.new).toList();
    LessonTracking.pracQuizScrView();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Total cards = questions + the terminal done card.
  int get _cardCount => _answers.length + 1;

  /// The done card is only reachable once every question has been graded.
  int get _furthestAllowed {
    for (var i = 0; i < _answers.length; i++) {
      if (!_answers[i].hasChecked) return i;
    }
    return _answers.length;
  }

  int get _correctCount => _answers.where((answer) => answer.isCorrect).length;

  void _onPageChanged(int page) {
    if (page >= _answers.length && !_completeViewTracked) {
      _completeViewTracked = true;
      LessonTracking.pracQuizCompleteScrView();
    }
    setState(() {
      _index = page;
      if (page > _furthest) _furthest = page;
    });
  }

  /// The sheet's question_type vocabulary for [answer]'s question. `single`
  /// covers every non-multi choice.
  String _questionTypeOf(QuizCardAnswer answer) {
    if (answer.isMultiChoice) return 'multiple';
    if (answer.isTextGap) return 'text_gap';
    if (answer.isArrange) return 'arrange';
    return 'single';
  }

  void _check(int index) {
    AppHaptic.select();
    setState(() {
      _answers[index].check();
      // Grading reveals the next card; the reader still has to swipe to it.
      _furthest = math.max(_furthest, _furthestAllowed);
    });
    LessonTracking.pracQuizCheckClick(
      questionType: _questionTypeOf(_answers[index]),
      isCorrect: _answers[index].isCorrect,
    );
    KeypointExerciseAction.trackResultViewed();
  }

  @override
  Widget build(BuildContext context) {
    // The peek card hides its practice entry when the keypoint has no playable
    // question, so this should be unreachable — but never render a dead deck.
    if (_answers.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop(<QuizCardAnswer>[]);
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.backgroundBrandSoft),
      body: ThemedBackground(
        child: SafePage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 0),
                child: _header(context),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(36.w, 6.h, 36.w, 0),
                child: _progress(context),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  onPageChanged: _onPageChanged,
                  // The gate, expressed as structure: an ungraded card simply has
                  // no next page to scroll into.
                  itemCount: math.min(_cardCount, math.max(_furthest, _furthestAllowed) + 1),
                  itemBuilder: (context, page) => Padding(
                    padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 28.h),
                    child: QuizDeckCardSurface(
                      child: page >= _answers.length ? _doneContent(context) : _questionContent(page),
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

  /// Design quiz header ("3 · Learning" → Quiz — question deck): close pinned
  /// LEFT, the settings grid pinned RIGHT — the same two controls, same chrome,
  /// as the reading deck's shell header — and no title text between them (the
  /// pips row underneath is the header's whole middle). It shipped as
  /// title + right-side X first, which is the HABIT quiz's header, not this
  /// screen's.
  Widget _header(BuildContext context) {
    return Row(
      children: [
        Semantics(
          button: true,
          label: context.l10n.common.close,
          child: GestureDetector(
            onTap: () {
              AppHaptic.select();
              // "Thoát giữa chừng" only: the X tapped while ON the summary
              // card is a completion, already reported by
              // prac_quiz_complete_scr_view, not a mid-quiz abandon.
              if (_index < _answers.length) LessonTracking.pracQuizExit();
              Navigator.of(context).pop(_answers);
            },
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 36.w,
              height: 36.w,
              child: Center(
                child: KeypointHeaderButtonChrome(
                  child: SvgPicture.asset(
                    AppAsset.svg.app.icKpClose,
                    width: 18.w,
                    height: 18.w,
                    colorFilter: const ColorFilter.mode(KeypointHeaderChrome.icon, BlendMode.srcIn),
                  ),
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        // Same sheet as the reading deck: Change theme, Text display, Speed,
        // Background music, Report a problem.
        LessonHeaderMenu(onReportProblem: () => _openReportIssueSheet(context)),
      ],
    );
  }

  /// Mirror of [LessonPage._openReportIssueSheet] — the quiz reports against
  /// the same keypoint the deck was reading. The cubit comes from DI, not
  /// `context.read`: this page sits on an imperative [MaterialPageRoute], and
  /// the lesson routes' `BlocProvider.value`s don't reach across routes — the
  /// DI instance IS the one those routes provide (`@lazySingleton`).
  void _openReportIssueSheet(BuildContext context) {
    final courseLessonState = AppDI.injector.get<CourseLessonCubit>().state;
    final keypoint = courseLessonState.resolvedCurrentKeypoint;
    ReportIssueSheet.show(
      context,
      lessonId: courseLessonState.selectedLesson.id,
      keypointId: keypoint.id,
      keypointTitle: keypoint.title.text,
      keypointImage: keypoint.image,
    );
  }

  /// One 6px pip per card including the done card — the design's quiz-mode pips
  /// (`flex: 1`, `height: 6px`, gap 3).
  Widget _progress(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _cardCount; i++) ...[
          if (i > 0) 3.horizontalSpace,
          Expanded(
            child: Container(
              height: 6.h,
              decoration: BoxDecoration(
                color: i <= _index
                    ? AppCustomColor.brandPrimary
                    : AppCustomColor.backgroundWhite.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(99.r),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _questionContent(int page) {
    return QuizQuestionCard(
      answer: _answers[page],
      reorderKeyPrefix: 'kp-quiz-arrange-$page',
      onChanged: () => setState(() {}),
      onCheck: () => _check(page),
    );
  }

  /// Terminal card (design `c.isDone`, quiz mode): pale-green disc, verdict,
  /// score pill, and a pill back to the keypoint. Lives INSIDE the deck, so
  /// swiping back to re-read an answer still works — exactly what the design's
  /// own subtitle promises.
  Widget _doneContent(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74.w,
              height: 74.w,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppCustomColor.kpResultCorrectSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, size: 34.w, color: AppCustomColor.successGreen),
            ),
            14.verticalSpace,
            AppText(
              context.l10n.lesson.practiceQuizDoneTitle,
              textAlign: TextAlign.center,
              style: AppStyle.text22.copyWith(
                fontWeight: FontWeight.w700,
                color: AppCustomColor.textPrimary,
              ),
            ),
            14.verticalSpace,
            AppText(
              context.l10n.lesson.practiceQuizDoneSubtitle,
              textAlign: TextAlign.center,
              maxLines: 3,
              style: AppStyle.text14.copyWith(height: 1.6, color: AppCustomColor.textTertiary),
            ),
            14.verticalSpace,
            Container(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppCustomColor.brandPrimary50,
                borderRadius: BorderRadius.circular(99.r),
              ),
              child: AppText(
                context.l10n.lesson.practiceQuizScore(
                  correct: '$_correctCount',
                  total: '${_answers.length}',
                ),
                style: AppStyle.textBold16.copyWith(color: AppCustomColor.brandPrimary),
              ),
            ),
            22.verticalSpace,
            // Design ("3 · Learning" → Sau Check): the quiz's terminal card ends
            // the whole lesson flow with "Back to roadmap" — not a pop back to
            // the hub. The imperatively pushed routes (this quiz, the practice
            // hub) must be popped BEFORE `.go`: they are not go_router pages, so
            // a location change alone would leave them stacked on top of the
            // roadmap it navigated to.
            QuizActionPill(
              label: context.l10n.lesson.practiceQuizDoneButton,
              isEnabled: true,
              onPressed: () {
                AppHaptic.select();
                // The lesson session truly ends here — same hygiene as the
                // completion page's own exit.
                unawaited(AppDI.injector.get<LiveActivityService>().end());
                unawaited(cancelLiveActivityReturnNudge());
                // `.go` FIRST: it only swaps the go_router pages underneath and
                // leaves this imperative route mounted, so `context` is still
                // live for it. Popping first would dispose this page and hand
                // `.go` a defunct context.
                CourseRoadmapRoute().go(context);
                // Pop only on the NEXT frame: the router applies the page swap
                // on its own build, so popping in the same tick reveals the
                // lesson-complete page for the frames in between — a flash of a
                // screen the reader already left. One frame later the roadmap
                // is what's underneath, and the pop lands straight on it.
                final navigator = Navigator.of(context);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  navigator.popUntil((route) => route.settings is Page);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
