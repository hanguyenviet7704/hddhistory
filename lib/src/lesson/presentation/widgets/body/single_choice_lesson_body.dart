part of '../../../lesson.dart';

/// Single-choice exercise card (Keypoint v2 design).
///
/// Checking and the verdict both live inside the card — see
/// [KeypointExerciseAction]. The result sheet this used to push over the deck is
/// gone: it covered the very options the reader had just weighed up, and its
/// Continue button duplicated the swipe the rest of the deck already uses.
class SingleChoiceLessonBody extends LessonBodyWidget {
  final Function(bool) onAnswerChecked;
  final bool isReadOnly;

  const SingleChoiceLessonBody({
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
        // Roleplay renders its own result surface around this body, so grading
        // there is not a keypoint-card event.
        final exerciseType = AppDI.injector.get<ExerciseCubit>().state.currentLearningItem.type;
        if (exerciseType == LearningItemType.roleplay) return;
        KeypointExerciseAction.trackResultViewed();
      },
      child: BlocBuilder<ChoiceCubit, ChoiceState>(
        builder: (context, state) {
          return _SingleChoiceQuestionContent(
            state: state,
            ignoreAnswers: isReadOnly,
            showInlineAction: true,
          );
        },
      ),
    );
  }

  @override
  Widget buildBottomButton(BuildContext context) {
    return _buildSingleChoiceBottomButton(context);
  }

  @override
  bool get rendersOwnAction => true;
}

class _SingleChoiceQuestionContent extends StatelessWidget {
  final ChoiceState state;
  final List<Widget> footer;
  final bool ignoreAnswers;

  /// Opt-in because this content block is shared with the no-correct-answer
  /// reflection question, which the v2 design does not cover and which keeps the
  /// sticky bottom button plus its own follow-up documents.
  final bool showInlineAction;

  const _SingleChoiceQuestionContent({
    required this.state,
    this.footer = const [],
    this.ignoreAnswers = false,
    this.showInlineAction = false,
  });

  @override
  Widget build(BuildContext context) {
    final currentQuestion = state.question;
    final instructionText = _resolveSingleChoiceInstruction(context, currentQuestion);

    return LessonContentCard(
      // Pinned to the card's bottom edge (design's `flex:1` spacer above it)
      // rather than trailing the last option.
      footer: showInlineAction
          ? KeypointExerciseAction(
              hasChecked: state.hasChecked,
              isCorrect: state.isCorrect,
              canCheck: !ignoreAnswers && state.selectedAnswerIndex != -1,
              onCheck: ignoreAnswers ? null : () => context.read<ChoiceCubit>().checkAnswer(),
              explanationText: state.question.explanationText,
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IgnorePointer(
            ignoring: ignoreAnswers,
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
                  text: instructionText,
                  accent: KeypointExerciseAccent.violet,
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.answerOptions.length,
                  separatorBuilder: (context, index) => 10.verticalSpace,
                  itemBuilder: (context, index) {
                    return ChoiceAnswerCard(
                      option: state.answerOptions[index],
                      isMultiChoice: false,
                      state: state.getAnswerState(index),
                      onTap: () => context.read<ChoiceCubit>().selectAnswer(index),
                    );
                  },
                ),
              ],
            ),
          ),
          ...footer,
        ],
      ),
    );
  }
}

String _resolveSingleChoiceInstruction(BuildContext context, QuestionEntity question) {
  return switch (question.typedPayload) {
    QuestionSingleChoiceNoCorrectAnswerPayloadEntity() => context.l10n.exercise.exerciseSingleChoiceNoCorrectAnswerInstruction,
    _ => context.l10n.exercise.exerciseSingleChoiceInstruction,
  };
}

Widget _buildSingleChoiceBottomButton(BuildContext context) {
  return BlocBuilder<ChoiceCubit, ChoiceState>(
    builder: (context, state) {
      final canCheck = state.selectedAnswerIndex != -1;

      return ExerciseContinueButton(
        onPressed: () {
          if (!canCheck) return;
          context.read<ChoiceCubit>().checkAnswer();
        },
        text: context.l10n.lesson.checkButton,
        isEnabled: canCheck,
      );
    },
  );
}
