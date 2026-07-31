part of '../../../lesson.dart';

/// Arrange-the-sequence exercise card (Keypoint v2 design).
///
/// Grading marks every row in place: a correct step turns green, a misplaced one
/// turns red and carries the position it belonged at (see
/// [ArrangeSequenceAnswerCard]). That is the whole correction, so the result
/// sheet that used to restate the ordered list is gone — only the verdict and
/// explanation remain, inside the card.
class ArrangeTheSequenceLessonBody extends LessonBodyWidget {
  final Function(bool) onAnswerChecked;
  final bool isReadOnly;

  const ArrangeTheSequenceLessonBody({
    super.key,
    required this.onAnswerChecked,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<ArrangeTheSequenceCubit, ArrangeTheSequenceState>(
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
      child: BlocBuilder<ArrangeTheSequenceCubit, ArrangeTheSequenceState>(
        builder: (context, state) {
          final currentQuestion = state.question;

          return LessonContentCard(
            // Pinned to the card's bottom edge (design's `flex:1` spacer above
            // it) rather than trailing the last step.
            footer: KeypointExerciseAction(
              hasChecked: state.hasChecked,
              isCorrect: state.isCorrect,
              canCheck: !isReadOnly && state.currentItems.isNotEmpty && !state.hasChecked,
              onCheck: isReadOnly ? null : () => context.read<ArrangeTheSequenceCubit>().checkAnswer(),
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
                        text: context.l10n.exercise.exerciseSequenceInstruction,
                        accent: KeypointExerciseAccent.green,
                      ),
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        padding: EdgeInsets.zero,
                        proxyDecorator: (child, index, animation) {
                          final cubit = context.read<ArrangeTheSequenceCubit>();
                          final currentState = cubit.state;
                          if (index < 0 || index >= currentState.currentItems.length) {
                            return child;
                          }
                          final item = currentState.currentItems[index];
                          final itemState = currentState.getItemState(index);

                          return ArrangeSequenceAnswerCard(
                            key: Key('drag-${item.id}'),
                            text: item.text.text,
                            index: index,
                            state: itemState,
                            dragEnabled: false,
                            isDragging: true,
                          );
                        },
                        onReorderItem: (oldIndex, newIndex) {
                          if (state.hasChecked) return;
                          context.read<ArrangeTheSequenceCubit>().reorderItems(oldIndex, newIndex);
                        },
                        itemCount: state.currentItems.length,
                        itemBuilder: (context, index) {
                          final item = state.currentItems[index];
                          return Padding(
                            key: Key('${item.id}'),
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: ArrangeSequenceAnswerCard(
                              text: item.text.text,
                              index: index,
                              state: state.getItemState(index),
                              dragEnabled: !state.hasChecked,
                              correctPosition: state.correctPositionFor(index),
                            ),
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
    return BlocBuilder<ArrangeTheSequenceCubit, ArrangeTheSequenceState>(
      builder: (context, state) {
        final canCheck = state.currentItems.isNotEmpty && !state.hasChecked;

        return ExerciseContinueButton(
          onPressed: canCheck ? () => context.read<ArrangeTheSequenceCubit>().checkAnswer() : null,
          text: context.l10n.lesson.checkButton,
          isEnabled: canCheck,
        );
      },
    );
  }

  @override
  bool get rendersOwnAction => true;
}
