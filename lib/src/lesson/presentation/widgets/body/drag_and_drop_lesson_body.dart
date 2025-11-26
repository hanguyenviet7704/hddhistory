part of '../../../lesson.dart';

class DragAndDropLessonBody extends StatelessWidget {
  final Function(bool) onAnswerChecked;

  const DragAndDropLessonBody({
    super.key,
    required this.onAnswerChecked,
  });

  void _showResultOverlay(BuildContext context, ResultType type) {
    LessonResultOverlayManager.show(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<DragAndDropCubit>(),
        child: BlocBuilder<DragAndDropCubit, DragAndDropState>(
          builder: (context, state) {
            final hasExplanation = state.question.explanation.text.isNotEmpty;

            return DragAndDropResultBottomSheet(
              type: type,
              showExplanation: state.showExplanation,
              explanationText: state.question.explanation.text,
              targetArea: state.question.targetArea.text,
              placedWords: state.placedWords,
              correctAnswers: state.question.answer.map((a) => a.correctAnswer.text).toList(),
              onContinue: () {
                LessonResultOverlayManager.hide();
                AppDI.injector.get<ExerciseCubit>().nextQuestion();
              },
              onExplain: hasExplanation ? () => context.read<DragAndDropCubit>().toggleExplanation() : null,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DragAndDropCubit, DragAndDropState>(
      listenWhen: (previous, current) {
        // Only trigger when hasChecked changes from false to true
        return !previous.hasChecked && current.hasChecked;
      },
      listener: (context, state) {
        onAnswerChecked(state.isCorrect);
        (context.findAncestorWidgetOfExactType<DragAndDropLessonBody>() as DragAndDropLessonBody)._showResultOverlay(
          context,
          state.isCorrect ? ResultType.correct : ResultType.incorrect,
        );
      },
      child: BlocBuilder<DragAndDropCubit, DragAndDropState>(
        builder: (context, state) {
          final currentQuestion = state.question;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentQuestion.document.any((document) => document.dataAvailable)) ...[
                DocumentWidget(documents: currentQuestion.document),
                12.verticalSpace,
              ],
              SentenceBuilder(
                placedWords: state.placedWords,
                targetArea: currentQuestion.targetArea.text,
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
                allWords: currentQuestion.options.map((option) => option.text.text).toList(),
                onWordReturnedFromSlot: (word, fromIndex) {
                  // Word is being dragged back to available area from a slot
                  context.read<DragAndDropCubit>().removeWord(fromIndex);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  /// Build the bottom button for drag and drop questions
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
