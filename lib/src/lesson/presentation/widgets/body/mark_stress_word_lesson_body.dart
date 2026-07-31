part of '../../../lesson.dart';

class MarkStressWordLessonBody extends LessonBodyWidget {
  final Function(bool) onAnswerChecked;
  final bool isReadOnly;

  const MarkStressWordLessonBody({
    super.key,
    required this.onAnswerChecked,
    this.isReadOnly = false,
  });

  void _showResultOverlay(
    BuildContext context,
    ResultType type, {
    bool isReview = false,
    bool showExplainAction = true,
  }) {
    LessonResultOverlayHelper.showResultOverlay(
      context: context,
      isReview: isReview,
      overlayBuilder: (parentContext, onContinue) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: parentContext.read<MarkStressWordCubit>()),
          BlocProvider.value(value: parentContext.read<LessonCubit>()),
        ],
        child: BlocBuilder<MarkStressWordCubit, MarkStressWordState>(
          builder: (context, state) {
            final hasExplanation = state.question.hasExplanation;
            return MarkStressWordResultBottomSheet(
              type: type,
              showExplanation: state.showExplanation,
              explanationText: state.question.explanationText,
              words: state.words,
              selectedIndices: state.selectedWordIndices,
              correctIndices: state.correctWordIndices,
              onContinue: onContinue,
              onExplain: showExplainAction && hasExplanation ? () => context.read<MarkStressWordCubit>().toggleExplanation() : null,
            );
          },
        ),
      ),
    );
  }

  void _handleExplainTap(BuildContext context, QuestionEntity currentQuestion, MarkStressWordState state) {
    if (isReadOnly) {
      context.read<LessonCubit>().consumePendingAdvance();
    }
    if (currentQuestion.hasExplanation && !state.showExplanation) {
      context.read<MarkStressWordCubit>().toggleExplanation();
    }
    _showResultOverlay(
      context,
      state.isCorrect ? ResultType.correct : ResultType.incorrect,
      isReview: isReadOnly,
      showExplainAction: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MarkStressWordCubit, MarkStressWordState>(
      listenWhen: (previous, current) {
        // Only trigger when hasChecked changes from false to true
        return !previous.hasChecked && current.hasChecked;
      },
      listener: (context, state) {
        onAnswerChecked(state.isCorrect);
        final bool isRoleplay = AppDI.injector.get<ExerciseCubit>().state.currentLearningItem.type == LearningItemType.roleplay;
        if (isRoleplay) return;
        _showResultOverlay(
          context,
          state.isCorrect ? ResultType.correct : ResultType.incorrect,
        );
      },
      child: BlocBuilder<MarkStressWordCubit, MarkStressWordState>(
        builder: (context, state) {
          final currentQuestion = state.question;
          final words = state.words;
          final isLessonExercise = context.select((ExerciseCubit bloc) => bloc.state.currentLearningItem.type == LearningItemType.exercise);
          final showExplainButton = isLessonExercise && isReadOnly && currentQuestion.hasExplanation;

          return LessonContentCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IgnorePointer(
                  ignoring: isReadOnly,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (currentQuestion.document.any((document) => document.dataAvailable)) ...[
                        DocumentWidget(
                          documents: currentQuestion.document,
                          asCard: false,
                        ),
                        12.verticalSpace,
                      ],
                      AppText(
                        context.l10n.exercise.exerciseStressMarkInstruction,
                        margin: EdgeInsets.symmetric(vertical: 8.h),
                        maxLines: 10,
                        style: AppStyle.text12.copyWith(
                          color: AppCustomColor.textSecondary,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                      12.verticalSpace,
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
                        alignment: Alignment.center,
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 2,
                              strokeAlign: BorderSide.strokeAlignOutside,
                              color: const Color(0xFFE3E8EF) /* Border-border-secondary */,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Wrap(
                          spacing: 2.w,
                          runSpacing: 6.h,

                          children: List.generate(
                            words.length,
                            (index) {
                              // Create a temporary OptionEntity for each word
                              final wordOption = OptionEntity(
                                id: index,
                                text: BaseMultiLanguage(en: words[index], vi: words[index], zh: words[index]),
                                value: BaseMultiLanguage(en: words[index], vi: words[index], zh: words[index]),
                              );

                              return MarkStressWordCard(
                                option: wordOption,
                                state: state.getWordState(index),
                                onTap: () => context.read<MarkStressWordCubit>().selectWord(index),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (showExplainButton) ...[
                  16.verticalSpace,
                  LessonExplainButton(
                    onTap: () => _handleExplainTap(context, currentQuestion, state),
                    hasExplanation: currentQuestion.hasExplanation,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget buildBottomButton(BuildContext context) {
    return BlocBuilder<MarkStressWordCubit, MarkStressWordState>(
      builder: (context, state) {
        final canCheck = state.selectedWordIndices.isNotEmpty && !state.hasChecked;

        return ExerciseContinueButton(
          onPressed: canCheck ? () => context.read<MarkStressWordCubit>().checkAnswer() : null,
          text: context.l10n.lesson.checkButton,
          isEnabled: canCheck,
        );
      },
    );
  }
}
