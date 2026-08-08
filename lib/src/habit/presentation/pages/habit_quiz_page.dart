part of '../../habit.dart';

/// Habit practice quiz (design "5 · Habit" → `Flow · Practice with a quiz`,
/// screen 3).
///
/// That screen's tile is labelled "1 màn đại diện" — one representative card —
/// because the design renders it by importing `_Keypoint Swipe Lab` with
/// `mode="quiz"`. So this is not a page per question with a Next button: it is
/// ONE VERTICALLY SWIPED DECK whose cards are the questions plus a terminal
/// "done" card. The deck's own data is
/// `QUIZ_TYPES = { single, multi, dnd, arr }` — four exercise types, not two.
///
/// ## Why this re-implements the deck instead of reusing [KeypointCardShell]
///
/// [KeypointCardShell] IS this design, already built — but it is driven by
/// `KeypointCardCubit`, which requires `LessonCubit` + `TheoryCubit` +
/// `LessonAudioCubit`, rebuilds its cards from lesson state, and carries
/// narration and in-lesson paywall gating. Driving it from a habit would mean
/// fabricating a lesson, which would file habit answers as progress on a course
/// the reader never opened and fight any lesson actually in flight.
///
/// The question rendering and per-card answer state ARE shared — see
/// [QuizQuestionCard] / [QuizCardAnswer] in the lesson feature, also used by
/// [KeypointQuizPage] — so a habit question renders identically to the same
/// question practised from its keypoint. What stays here is what makes this
/// deck a HABIT one: submitting the attempt files the day's check-in.
///
/// Swiping forward past the live card is structurally impossible rather than
/// merely guarded: the deck is built with `itemCount: _furthestIndex + 1`, the
/// same trick [KeypointCardShell] uses, so an ungraded card has no next page to
/// scroll to. Swiping BACK is always free — the design's own done card says
/// "Swipe down to revisit any question."
class HabitQuizPage extends StatefulWidget {
  final UserHabitEntity userHabit;
  final HabitPracticeEntity practice;

  const HabitQuizPage({super.key, required this.userHabit, required this.practice});

  /// Pushed imperatively rather than through a typed go_router route because it
  /// carries entities, and the repo has no `$extra` typed routes to follow.
  /// Resolves to `true` when the attempt was filed, so the caller can refresh.
  static Future<bool?> push(
    BuildContext context, {
    required UserHabitEntity userHabit,
    required HabitPracticeEntity practice,
  }) {
    return Navigator.of(context).push<bool>(
      habitModalRoute(
        BlocProvider.value(
          value: AppDI.injector.get<HabitCubit>(),
          child: HabitQuizPage(userHabit: userHabit, practice: practice),
        ),
      ),
    );
  }

  @override
  State<HabitQuizPage> createState() => _HabitQuizPageState();
}

class _HabitQuizPageState extends State<HabitQuizPage> {
  late final PageController _pageController = PageController();
  late final List<QuizCardAnswer> _answers;

  /// Index of the card on screen, and the furthest one revealed so far. They
  /// differ whenever the reader has swiped back to review.
  int _index = 0;
  int _furthest = 0;

  bool _isSubmitting = false;
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    _answers = widget.practice.playableQuestions.map(QuizCardAnswer.new).toList();
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

  bool get _isDoneCard => _index >= _answers.length;

  void _onPageChanged(int page) {
    setState(() {
      _index = page;
      if (page > _furthest) _furthest = page;
    });
    if (_isDoneCard) _submit();
  }

  void _check(int index) {
    AppHaptic.select();
    setState(() {
      _answers[index].check();
      // Grading reveals the next card; the reader still has to swipe to it.
      _furthest = math.max(_furthest, _furthestAllowed);
    });
    KeypointExerciseAction.trackResultViewed();
  }

  /// Files the attempt once, when the done card is first reached. Deliberately
  /// NOT on the last Check: the reader can still swipe back and read their
  /// answers, and a submission that fired earlier would have to be reconciled
  /// with a second one.
  Future<void> _submit() async {
    if (_hasSubmitted || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    final ok = await context.read<HabitCubit>().submitPracticeAttempt(
      userHabitId: widget.userHabit.id,
      method: HabitCheckinMethodEntity.exercise,
      learningItemId: widget.practice.learningItemId,
      exercisesResult: _answers.map((answer) => answer.toResult()).toList(),
      score: _correctCount,
      total: _answers.length,
    );

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _hasSubmitted = ok;
    });

    if (!ok) {
      context.showDSnackBar(message: context.l10n.common.errorSomethingHappened, type: MessageType.error);
      return;
    }
    HabitTracking.noteCheckin(widget.userHabit, hasNote: false);
  }

  @override
  Widget build(BuildContext context) {
    // A practice with no playable question should never have opened this screen
    // — PracticePickSheet hides the quiz row in that case — but a content edit
    // between the list fetch and the tap can still land here.
    if (_answers.isEmpty) return _emptyState(context);

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
                      child: page >= _answers.length
                          ? _doneContent(context)
                          : QuizQuestionCard(
                              answer: _answers[page],
                              reorderKeyPrefix: 'habit-arrange-$page',
                              onChanged: () => setState(() {}),
                              onCheck: () => _check(page),
                            ),
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

  Widget _emptyState(BuildContext context) {
    return Scaffold(
      backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.backgroundBrandSoft),
      body: ThemedBackground(
        child: SafePage(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    context.l10n.habit.quizEmptyTitle,
                    textAlign: TextAlign.center,
                    style: AppStyle.textBold18.copyWith(
                      color: studyThemeOnBg(context, AppCustomColor.textPrimary),
                    ),
                  ),
                  20.verticalSpace,
                  QuizActionPill(
                    label: context.l10n.habit.practiceDoneButton,
                    isEnabled: true,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        HabitDomainIcon(skillsetId: widget.userHabit.habit?.skillsetId ?? '', imageUrl: widget.userHabit.habit?.image ?? '', size: 38),
        12.horizontalSpace,
        Expanded(
          child: AppText(
            widget.userHabit.displayTitle,
            maxLines: 2,
            // Design 15/700; the app's scale has no 15.
            style: AppStyle.text16.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: studyThemeOnBg(context, AppCustomColor.textPrimary),
            ),
          ),
        ),
        8.horizontalSpace,
        GestureDetector(
          onTap: () {
            AppHaptic.select();
            // The attempt is already filed if the deck was finished, so leaving
            // never loses a completed check-in.
            Navigator.of(context).pop(_hasSubmitted);
          },
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 34.w,
            height: 34.w,
            child: Icon(Icons.close, size: 22.w, color: studyThemeOnBg(context, AppCustomColor.textTertiary)),
          ),
        ),
      ],
    );
  }

  /// One 6px pip per card including the done card — the design's quiz-mode pips
  /// (`flex: 1`, `height: 6px`, gap 3). No "2/5" caption: the segments carry the
  /// count, and a number over a photo background needed a scrim to stay legible.
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

  //* ---------------- Done card ----------------

  /// Terminal card of the deck (design `c.isDone`): a solid pale-green disc, the
  /// verdict, and a pill sized to its label. Lives INSIDE the deck, so swiping
  /// back to re-read an answer still works — which is exactly what the design's
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
              context.l10n.habit.practiceDoneTitle,
              textAlign: TextAlign.center,
              style: AppStyle.text22.copyWith(
                fontWeight: FontWeight.w700,
                color: AppCustomColor.textPrimary,
              ),
            ),
            14.verticalSpace,
            AppText(
              context.l10n.habit.quizDoneSwipeSubtitle,
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
                context.l10n.habit.practiceDoneScore(
                  correct: '$_correctCount',
                  total: '${_answers.length}',
                ),
                style: AppStyle.textBold16.copyWith(color: AppCustomColor.brandPrimary),
              ),
            ),
            22.verticalSpace,
            QuizActionPill(
              label: context.l10n.habit.practiceDoneButton,
              isEnabled: !_isSubmitting,
              isLoading: _isSubmitting,
              onPressed: () {
                AppHaptic.select();
                Navigator.of(context).pop(_hasSubmitted);
              },
            ),
          ],
        ),
      ),
    );
  }
}
