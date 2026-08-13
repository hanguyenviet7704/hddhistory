part of '../../../lesson.dart';

/// Text-gap-filling exercise card (Keypoint v2 design).
///
/// The sentence sits as bare prose on the card with dashed inline gaps, the word
/// bank below it has no tray, and grading resolves in place: a wrong answer gets
/// the model sentence stacked directly above the verdict (see
/// [GapFillCorrectAnswerPanel]) instead of a sheet over the deck.
class DragAndDropLessonBody extends LessonBodyWidget {
  final Function(bool) onAnswerChecked;
  final bool isReadOnly;

  const DragAndDropLessonBody({
    super.key,
    required this.onAnswerChecked,
    this.isReadOnly = false,
  });

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
        KeypointExerciseAction.trackResultViewed();
      },
      child: BlocBuilder<DragAndDropCubit, DragAndDropState>(
        builder: (context, state) {
          final currentQuestion = state.question;
          final targetArea = questionRuntimeTargetArea(currentQuestion).text;

          return LessonContentCard(
            // Pinned to the card's bottom edge (design's `flex:1` spacer above
            // it) rather than trailing the word bank.
            footer: KeypointExerciseAction(
              hasChecked: state.hasChecked,
              isCorrect: state.isCorrect,
              canCheck: !isReadOnly && state.isAllFilled,
              onCheck: isReadOnly ? null : () => context.read<DragAndDropCubit>().checkAnswer(),
              explanationText: currentQuestion.explanationText,
              correctAnswer: GapFillCorrectAnswerPanel(
                targetArea: targetArea,
                correctAnswers: questionRuntimeAnswers(currentQuestion).map((answer) => answer.correctAnswer.text).toList(),
              ),
            ),
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
                          prose: DocumentProse.question,
                        ),
                        12.verticalSpace,
                      ],
                      SentenceBuilder(
                        placedWords: state.placedWords,
                        targetArea: targetArea,
                        answerCount: state.dropZoneCount,
                        onWordPlaced: (index, word, fromIndex) {
                          context.read<DragAndDropCubit>().placeWord(index, word, fromIndex);
                        },
                        onWordRemoved: (index) {
                          context.read<DragAndDropCubit>().removeWord(index);
                        },
                        getSlotState: (index) => state.getSlotState(index),
                        onSlotTapped: state.hasChecked
                            ? null
                            : (index) => context.read<DragAndDropCubit>().removeWord(index),
                      ),
                      18.verticalSpace,
                      KeypointExerciseInstruction(
                        text: context.l10n.exercise.exerciseGapFillingInstruction,
                      ),
                      AnswerCardsArea(
                        availableWords: state.availableWords,
                        onWordReturnedFromSlot: (word, fromIndex) {
                          context.read<DragAndDropCubit>().removeWord(fromIndex);
                        },
                        // Same rule as the practice deck: the tapped word lands
                        // in the first empty gap, and a full sentence ignores
                        // the tap rather than overwriting a placed answer.
                        onWordTapped: state.hasChecked
                            ? null
                            : (word) {
                                final slot = state.firstEmptySlot;
                                if (slot == null) return;
                                context.read<DragAndDropCubit>().placeWord(slot, word, null);
                              },
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
          text: context.l10n.lesson.checkButton,
          isEnabled: canCheck,
        );
      },
    );
  }

  @override
  bool get rendersOwnAction => true;
}
