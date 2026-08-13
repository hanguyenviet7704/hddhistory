part of '../../../lesson.dart';

/// Multiple-choice exercise card (Keypoint v2 design). Checking and the verdict
/// live inside the card — see [KeypointExerciseAction] and the note on
/// [SingleChoiceLessonBody] for why the result sheet went away.
class MultipleChoiceLessonBody extends LessonBodyWidget {
  final Function(bool) onAnswerChecked;
  final bool isReadOnly;

  const MultipleChoiceLessonBody({
    super.key,
    required this.onAnswerChecked,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChoiceCubit, ChoiceState>(
      listenWhen: (previous, current) {
        // Only trigger when hasChecked changes from false to true
        return !previous.hasChecked && current.hasChecked;
      },
      listener: (context, state) {
        onAnswerChecked(state.isCorrect);
        final bool isRoleplay = AppDI.injector.get<ExerciseCubit>().state.currentLearningItem.type == LearningItemType.roleplay;
        if (isRoleplay) return;
        KeypointExerciseAction.trackResultViewed();
      },
      child: BlocBuilder<ChoiceCubit, ChoiceState>(
        builder: (context, state) {
          final currentQuestion = state.question;

          return LessonContentCard(
            // Pinned to the card's bottom edge (design's `flex:1` spacer above
            // it) rather than trailing the last option.
            footer: KeypointExerciseAction(
              hasChecked: state.hasChecked,
              isCorrect: state.isCorrect,
              canCheck: !isReadOnly && state.selectedAnswersIndices.isNotEmpty,
              onCheck: isReadOnly ? null : () => context.read<ChoiceCubit>().checkAnswer(),
              explanationText: currentQuestion.explanationText,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IgnorePointer(
                  ignoring: isReadOnly,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (currentQuestion.document.isNotEmpty) ...[
                        DocumentWidget(
                          documents: currentQuestion.document,
                          asCard: false,
                          prose: DocumentProse.question,
                        ),
                        8.verticalSpace,
                      ],
                      KeypointExerciseInstruction(
                        text: context.l10n.exercise.exerciseMultiChoicesInstruction,
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.answerOptions.length,
                        separatorBuilder: (context, index) => 10.verticalSpace,
                        itemBuilder: (context, index) {
                          return MultipleChoiceAnswerCard(
                            option: state.answerOptions[index],
                            state: state.getAnswerState(index),
                            onTap: () => context.read<ChoiceCubit>().selectAnswer(index),
                          );
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
    return BlocBuilder<ChoiceCubit, ChoiceState>(
      builder: (context, state) {
        final canCheck = state.selectedAnswersIndices.isNotEmpty;

        return ExerciseContinueButton(
          onPressed: canCheck ? () => context.read<ChoiceCubit>().checkAnswer() : null,
          text: context.l10n.lesson.checkButton,
          isEnabled: canCheck,
        );
      },
    );
  }

  @override
  bool get rendersOwnAction => true;
}
