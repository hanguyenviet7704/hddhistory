part of '../../habit.dart';

/// Habit quiz (design "5 · Habit" → Flow · Practice with a quiz).
///
/// Deliberately habit-local rather than reusing the lesson deck. `ChoiceCubit`
/// — where the lesson keeps select/check/grade — is a `@lazySingleton` that
/// reads the open lesson through `ExerciseCubit` / `CourseLessonCubit` /
/// `HomeCubit` and writes `user_progress` against that lesson's course and
/// keypoint. Driving it from here would file a habit answer as lesson progress
/// for a course the user isn't in, and fight an in-flight lesson for the single
/// instance. Only the DATA entities are shared ([QuestionEntity] and its
/// payload union); none of the lesson's state is touched.
///
/// Choice questions only, on purpose — see
/// [HabitPracticeEntityX.playableQuestions]. Drag-drop and speaking carry their
/// own interaction models and no authored habit content uses them yet.
class HabitQuizPage extends StatefulWidget {
  final UserHabitEntity userHabit;
  final HabitPracticeEntity practice;

  const HabitQuizPage({super.key, required this.userHabit, required this.practice});

  /// Resolves to `true` when the practice was submitted (and so the day was
  /// checked in), letting the caller refresh.
  static Future<bool?> push(
    BuildContext context, {
    required UserHabitEntity userHabit,
    required HabitPracticeEntity practice,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
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
  late final List<QuestionEntity> _questions = widget.practice.playableQuestions;

  int _index = 0;
  final Set<int> _selected = {};
  bool _graded = false;
  bool _isSubmitting = false;

  /// One entry per answered question, in the `ExerciseResult` shape the API
  /// stores — the same shape user-progress uses for lesson exercises.
  final List<Map<String, dynamic>> _results = [];
  int _correctCount = 0;

  QuestionEntity get _question => _questions[_index];
  bool get _isMulti => _question.type == QuestionTypeEnum.multipleChoice;
  bool get _isLast => _index == _questions.length - 1;

  List<QuestionChoiceOptionEntity> get _options => switch (_question.typedPayload) {
    QuestionSingleChoicePayloadEntity(:final options) => options,
    QuestionMultipleChoicePayloadEntity(:final options) => options,
    _ => const [],
  };

  /// Correct when the selected set matches the correct set exactly — for
  /// multiple choice, missing a correct option is as wrong as adding an
  /// incorrect one.
  bool get _isCorrect {
    final correct = <int>{};
    for (var i = 0; i < _options.length; i++) {
      if (_options[i].isCorrect) correct.add(i);
    }
    return _selected.length == correct.length && _selected.containsAll(correct);
  }

  void _toggle(int index) {
    if (_graded) return;
    AppHaptic.select();
    setState(() {
      if (_isMulti) {
        _selected.contains(index) ? _selected.remove(index) : _selected.add(index);
      } else {
        _selected
          ..clear()
          ..add(index);
      }
    });
  }

  void _check() {
    if (_selected.isEmpty || _graded) return;
    final correct = _isCorrect;
    correct ? AppHaptic.success() : AppHaptic.select();
    setState(() {
      _graded = true;
      if (correct) _correctCount += 1;
      _results.add(_buildResult(correct));
    });
  }

  Map<String, dynamic> _buildResult(bool passed) {
    final chosen = _selected.toList()..sort();
    final answers = chosen
        .map((i) => {'value': _options[i].value.toJson(), 'isCorrect': _options[i].isCorrect})
        .toList();

    return {
      'exerciseId': _question.exerciseId,
      'type': _isMulti ? 'multiple_choice' : 'single_choice',
      'passed': passed,
      'score': passed ? 1 : 0,
      if (_isMulti) 'multipleAnswer': answers,
      if (!_isMulti && answers.isNotEmpty) 'singleAnswer': answers.first,
    };
  }

  Future<void> _next() async {
    if (!_isLast) {
      setState(() {
        _index += 1;
        _selected.clear();
        _graded = false;
      });
      return;
    }
    await _submit();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    // One request: the server records the attempt AND files the day's check-in.
    // Never follow this with checkIn() — both write the same {habit, date} row.
    final ok = await context.read<HabitCubit>().submitPracticeAttempt(
      userHabitId: widget.userHabit.id,
      method: HabitCheckinMethodEntity.exercise,
      learningItemId: widget.practice.learningItemId,
      exercisesResult: _results,
      total: _questions.length,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!ok) {
      context.showDSnackBar(message: context.l10n.common.errorSomethingHappened, type: MessageType.error);
      return;
    }

    HabitTracking.noteCheckin(widget.userHabit, hasNote: false);
    await PracticeDonePage.push(
      context,
      userHabit: widget.userHabit,
      correct: _correctCount,
      total: _questions.length,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    // A practice with no playable question should never have reached here — the
    // picker hides the quiz row in that case — but render an explicit empty
    // state rather than crashing on an out-of-range index if it ever does.
    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.backgroundBrandSoft),
        body: SafePage(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: AppText(
                context.l10n.habit.detailDiaryEmpty,
                textAlign: TextAlign.center,
                style: AppStyle.text14.copyWith(color: AppCustomColor.textTertiary),
              ),
            ),
          ),
        ),
      );
    }

    // Layout follows the design's quiz deck: header, pips, then ONE card that
    // owns the rest of the screen — including the Check pill and the verdict.
    // Nothing sits below the card, which is why there is no screen-wide bottom
    // button here.
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
                child: Padding(
                  padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 28.h),
                  child: _card(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        HabitDomainIcon(skillsetId: widget.userHabit.habit?.skillsetId ?? '', size: 38),
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
            Navigator.of(context).pop();
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

  /// Segmented progress, one 6px pip per question — the design's quiz-mode pips
  /// (`flex: 1`, `height: 6px`, gap 3). No "2/5" caption: the design carries the
  /// count in the segments themselves, and a number over a photo background
  /// needed a scrim to stay readable.
  Widget _progress(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < _questions.length; i++) ...[
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

  /// The design's quiz card: one panel that owns the whole area under the pips
  /// and holds the question, the options, the Check pill and the verdict.
  ///
  /// Built from the Keypoint v2 widgets ([ChoiceAnswerCard],
  /// [KeypointExerciseInstruction], [KeypointExerciseAction]) because the design
  /// for this screen IS the keypoint swipe deck in `mode="quiz"` — same card,
  /// same option states, same result banner. Reusing them means the habit quiz
  /// cannot drift from the lesson deck it is meant to look identical to. Only
  /// the widgets are shared; none of the lesson's cubits are touched (see the
  /// class docblock).
  Widget _card(BuildContext context) {
    return ThemedGlassCard(
      // Frosted over a custom study background, solid white on the default
      // preset — the design's `rgba(255,255,255,.62)` card over the themed
      // wallpaper.
      frosted: true,
      radius: 22,
      padding: EdgeInsets.all(22.w),
      shadow: [
        BoxShadow(
          color: AppCustomColor.textPrimary.withValues(alpha: 0.05),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question first, instruction under it — the design's order. Leading
          // with "Select the best answer" buried the actual question.
          AppText(
            _question.questionText,
            maxLines: 8,
            style: AppStyle.text18.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.35,
              color: AppCustomColor.textPrimary,
            ),
          ),
          4.verticalSpace,
          KeypointExerciseInstruction(
            text: _isMulti ? context.l10n.habit.quizSelectMany : context.l10n.habit.quizSelectOne,
            accent: _isMulti ? KeypointExerciseAccent.green : KeypointExerciseAccent.violet,
          ),
          // Expanded, not Flexible: the design puts a `flex:1` spacer BETWEEN the
          // options and the action, so the pill sits at the BOTTOM of the card.
          // A loose Flexible let the scroll view shrink to its content and the
          // pill rode up under the last option with the void beneath it.
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (var i = 0; i < _options.length; i++) ...[
                    if (i > 0) 10.verticalSpace,
                    ChoiceAnswerCard(
                      option: OptionEntity(value: _options[i].value, isCorrect: _options[i].isCorrect),
                      isMultiChoice: _isMulti,
                      state: _answerState(i),
                      onTap: () => _toggle(i),
                    ),
                  ],
                ],
              ),
            ),
          ),
          14.verticalSpace,
          if (!_graded)
            _pill(
              context,
              label: context.l10n.habit.quizCheckButton,
              isEnabled: _selected.isNotEmpty,
              onPressed: _check,
            )
          else ...[
            KeypointExerciseAction(
              hasChecked: true,
              isCorrect: _isCorrect,
              explanationText: _question.explanationText,
            ),
            14.verticalSpace,
            _pill(
              context,
              label: context.l10n.habit.quizNextButton,
              isEnabled: !_isSubmitting,
              isLoading: _isSubmitting,
              onPressed: _next,
            ),
          ],
        ],
      ),
    );
  }

  /// Maps this question's selection + grading onto the five states
  /// [ChoiceAnswerCard] draws, which are exactly the design's five: untouched,
  /// selected, right-and-picked, wrong-and-picked, and right-but-missed. The
  /// fifth (`disabled`) is a wrong option left alone, which recedes.
  AnswerState _answerState(int index) {
    final isSelected = _selected.contains(index);
    if (!_graded) return isSelected ? AnswerState.selected : AnswerState.normal;
    final isCorrect = _options[index].isCorrect;
    if (isSelected && isCorrect) return AnswerState.correct;
    if (isSelected && !isCorrect) return AnswerState.incorrect;
    if (isCorrect) return AnswerState.correctNotSelected;
    return AnswerState.disabled;
  }

  /// The design's in-card action pill: centred, sized to its label with a 168
  /// minimum, 46 tall, and disabled in low-saturation brand rather than grey so
  /// it still reads as the next thing to press.
  ///
  /// Not [KeypointCheckAnswerButton]: that one hardcodes the lesson's
  /// "Check answer" string, and this screen needs both Check and Continue in the
  /// habit feature's own five locales.
  Widget _pill(
    BuildContext context, {
    required String label,
    required bool isEnabled,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return Center(
      child: Semantics(
        button: true,
        enabled: isEnabled,
        child: Material(
          color: isEnabled ? AppCustomColor.brandPrimary : AppCustomColor.kpCheckDisabled,
          borderRadius: BorderRadius.circular(999.r),
          child: InkWell(
            borderRadius: BorderRadius.circular(999.r),
            onTap: isEnabled
                ? () {
                    AppHaptic.select();
                    onPressed();
                  }
                : null,
            // No `alignment` here: it would turn the box into an Align that
            // expands to the card width instead of hugging the label.
            child: Container(
              constraints: BoxConstraints(minWidth: 168.w),
              height: 46.h,
              padding: EdgeInsets.symmetric(horizontal: 26.w),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppCustomColor.textWhite),
                    )
                  else
                    AppText(
                      label,
                      style: AppStyle.text16.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppCustomColor.textWhite,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
