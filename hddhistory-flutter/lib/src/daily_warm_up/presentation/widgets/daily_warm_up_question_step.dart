part of '../../daily_warm_up.dart';

class DailyWarmUpQuestionStep extends StatelessWidget {
  const DailyWarmUpQuestionStep({
    super.key,
    required this.state,
    required this.onClose,
    required this.onCheck,
    required this.onSelectChoice,
    required this.onSetOrderedOptionIds,
    required this.onPlaceOption,
    required this.onRemovePlacedOption,
    required this.onToggleWordIndex,
    this.applyStudyTheme = false,
  });

  final DailyWarmUpState state;
  final VoidCallback onClose;
  final VoidCallback onCheck;
  final ValueChanged<int> onSelectChoice;
  final ValueChanged<List<int>> onSetOrderedOptionIds;
  final void Function(int slotIndex, int optionId) onPlaceOption;
  final ValueChanged<int> onRemovePlacedOption;
  final ValueChanged<int> onToggleWordIndex;

  /// Opts this step into the study-theme treatment (design item 11). Only the
  /// `warm_up` feature's return-refresher quiz sets this — the daily_warm_up
  /// mini check-in (this same widget's other call site) is out of scope for
  /// the study theme rollout and must stay pixel-identical regardless of
  /// whichever background preset happens to be active elsewhere in the app.
  final bool applyStudyTheme;

  @override
  Widget build(BuildContext context) {
    final question = state.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    // Only true once the user has picked a custom study background AND this
    // call site opted in — gates the question card below so the stock look
    // (bare content directly on the white Scaffold) stays byte-for-byte
    // unchanged everywhere else.
    final isCustomBg = applyStudyTheme && context.watch<StudyThemeCubit>().state.preset.isCustom;

    final questionKey = ValueKey('${question.id}-${state.currentQuestionIndex}');
    final questionContent = ListView(
      padding: EdgeInsets.only(bottom: 20.h),
      children: [
        24.verticalSpace,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: AppText(
            question.questionText,
            maxLines: 12,
            style: AppStyle.text20.copyWith(
              color: const Color(0xFF0D121C),
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
        ),
        20.verticalSpace,
        _buildQuestionBody(context, question),
      ],
    );

    return Scaffold(
      backgroundColor: applyStudyTheme ? studyThemeScaffoldColor(context, Colors.white) : Colors.white,
      body: _wrapWithBackgroundIfNeeded(
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        AppHaptic.select();
                        onClose();
                      },
                      icon: Icon(
                        Icons.close_rounded,
                        color: applyStudyTheme ? studyThemeOnBg(context, const Color(0xFF0D121C)) : const Color(0xFF0D121C),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: DailyWarmUpProgressDots(
                          count: state.usableQuestions.length,
                          currentIndex: state.currentQuestionIndex,
                        ),
                      ),
                    ),
                    SizedBox(width: 48.w),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOutCubic,
                  // "The question card" (design item 11) — only rendered as a
                  // frosted panel over a custom background; the Default look
                  // (content flush on white) is untouched. Keyed by
                  // question+index (regardless of wrapping) so
                  // AnimatedSwitcher still cross-fades between questions.
                  child: isCustomBg
                      ? Padding(
                          key: questionKey,
                          padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
                          child: ThemedGlassCard(
                            radius: 24,
                            padding: EdgeInsets.zero,
                            // ThemedGlassCard already clips its child to the
                            // rounded shape (no extra ClipRRect needed here).
                            child: questionContent,
                          ),
                        )
                      : KeyedSubtree(key: questionKey, child: questionContent),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DailyWarmUpBottomCta(
        label: context.l10n.dailyWarmUp.check,
        enabled: state.canCheckCurrentQuestion,
        onPressed: onCheck,
        enableSafeArea: true,
      ),
    );
  }

  Widget _wrapWithBackgroundIfNeeded(Widget child) {
    return applyStudyTheme ? ThemedBackground(child: child) : child;
  }

  Widget _buildQuestionBody(BuildContext context, QuestionEntity question) {
    final payload = question.typedPayload;
    return switch (payload) {
      QuestionSingleChoicePayloadEntity() || QuestionMultipleChoicePayloadEntity() || QuestionSingleChoiceNoCorrectAnswerPayloadEntity() => DailyWarmUpChoiceBody(
        state: state,
        question: question,
        onSelectChoice: onSelectChoice,
      ),
      QuestionDragAndDropPayloadEntity(:final answers) => DailyWarmUpDragDropBody(
        state: state,
        question: question,
        slotCount: answers.length,
        onPlaceOption: onPlaceOption,
        onRemovePlacedOption: onRemovePlacedOption,
      ),
      QuestionArrangeTheSequencePayloadEntity() => DailyWarmUpArrangeBody(
        state: state,
        question: question,
        onSetOrderedOptionIds: onSetOrderedOptionIds,
      ),
      QuestionCuesPlacementPayloadEntity(:final targetArea) => DailyWarmUpCuesBody(
        state: state,
        question: question,
        words: _targetWords(targetArea),
        onPlaceOption: onPlaceOption,
        onRemovePlacedOption: onRemovePlacedOption,
      ),
      QuestionStressPlacementPayloadEntity(:final targetArea) => DailyWarmUpStressBody(
        state: state,
        words: _targetWords(targetArea),
        onToggleWordIndex: onToggleWordIndex,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}
