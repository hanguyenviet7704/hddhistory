part of '../../../lesson.dart';

class DragAndDropLessonBody extends LessonBodyWidget {
  final Function(bool) onAnswerChecked;
  final bool isReadOnly;

  const DragAndDropLessonBody({
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
          BlocProvider.value(value: parentContext.read<DragAndDropCubit>()),
          BlocProvider.value(value: parentContext.read<LessonCubit>()),
        ],
        child: BlocBuilder<DragAndDropCubit, DragAndDropState>(
          builder: (context, state) {
            final hasExplanation = state.question.hasExplanation;
            return DragAndDropResultBottomSheet(
              type: type,
              showExplanation: state.showExplanation,
              explanationText: state.question.explanationText,
              targetArea: questionRuntimeTargetArea(state.question).text,
              placedWords: state.placedWords,
              correctAnswers: questionRuntimeAnswers(state.question).map((a) => a.correctAnswer.text).toList(),
              onContinue: onContinue,
              onExplain: showExplainAction && hasExplanation
                  ? () => context.read<DragAndDropCubit>().toggleExplanation()
                  : null,
            );
          },
        ),
      ),
    );
  }

  void _handleExplainTap(BuildContext context, QuestionEntity currentQuestion, DragAndDropState state) {
    if (isReadOnly) {
      context.read<LessonCubit>().consumePendingAdvance();
    }
    if (currentQuestion.hasExplanation && !state.showExplanation) {
      context.read<DragAndDropCubit>().toggleExplanation();
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
    return BlocListener<DragAndDropCubit, DragAndDropState>(
      listenWhen: (previous, current) {
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
      child: BlocBuilder<DragAndDropCubit, DragAndDropState>(
        builder: (context, state) {
          final currentQuestion = state.question;
          final isLessonExercise = context.select((ExerciseCubit bloc) => bloc.state.currentLearningItem.type == LearningItemType.exercise);
          final showExplainButton = isLessonExercise && isReadOnly && currentQuestion.hasExplanation;

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentQuestion.document.any((document) => document.dataAvailable)) ...[
                DocumentWidget(documents: currentQuestion.document),
                12.verticalSpace,
              ],
              SentenceBuilder(
                placedWords: state.placedWords,
                targetArea: questionRuntimeTargetArea(currentQuestion).text,
                answerCount: state.dropZoneCount,
                onWordPlaced: (index, word, fromIndex) {
                  context.read<DragAndDropCubit>().placeWord(index, word, fromIndex);
                },
                onWordRemoved: (index) {
                  context.read<DragAndDropCubit>().removeWord(index);
                },
                getSlotState: (index) => state.getSlotState(index),
              ),
              24.verticalSpace,
              AppText(
                context.text.exercise.exerciseGapFillingInstruction,
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                style: AppStyle.text12.copyWith(
                  color: const Color(0xFF7F8EA4).withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
              12.verticalSpace,
              AnswerCardsArea(
                availableWords: state.availableWords,
                allWords: questionRuntimeOptions(currentQuestion).map((option) => option.labelText).where((text) => text.isNotEmpty).toList(),
                onWordReturnedFromSlot: (word, fromIndex) {
                  // Word is being dragged back to available area from a slot
                  context.read<DragAndDropCubit>().removeWord(fromIndex);
                },
              ),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IgnorePointer(ignoring: isReadOnly, child: content),
              if (showExplainButton) ...[
                12.verticalSpace,
                LessonExplainButton(
                  onTap: () => _handleExplainTap(context, currentQuestion, state),
                  hasExplanation: currentQuestion.hasExplanation,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  @override
  Widget buildBottomButton(BuildContext context) {
    return BlocBuilder<DragAndDropCubit, DragAndDropState>(
      builder: (context, state) {
        final canCheck = state.isAllFilled;

        return ExerciseContinueButton(
          onPressed: canCheck ? () => context.read<DragAndDropCubit>().checkAnswer() : null,
          text: context.text.lesson.checkButton,
          isEnabled: canCheck,
        );
      },
    );
  }
}
