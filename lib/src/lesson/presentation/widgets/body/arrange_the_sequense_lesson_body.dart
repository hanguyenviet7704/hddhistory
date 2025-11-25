part of '../../../lesson.dart';

class ArrangeTheSequenceLessonBody extends StatelessWidget {
  final Function(bool) onAnswerChecked;

  const ArrangeTheSequenceLessonBody({
    super.key,
    required this.onAnswerChecked,
  });

  void _showResultOverlay(BuildContext context, ResultType type) {
    LessonResultOverlayManager.show(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<ArrangeTheSequenceCubit>(),
        child: BlocBuilder<ArrangeTheSequenceCubit, ArrangeTheSequenceState>(
          builder: (context, state) {
            final correctAnswers = state.question.answer.map((answer) {
              return state.question.options.firstWhere(
                (option) => option.id == answer.id,
                orElse: () => const OptionEntity(),
              );
            }).toList();
            final hasExplanation = state.question.explanation.text.isNotEmpty;

            return ArrangeSequenceResultBottomSheet(
              type: type,
              showExplanation: state.showExplanation,
              explanationText: state.question.explanation.text,
              arrangedAnswers: correctAnswers,
              onContinue: () {
                LessonResultOverlayManager.hide();
                AppDI.injector.get<ExerciseCubit>().nextQuestion();
              },
              onExplain: hasExplanation ? () => context.read<ArrangeTheSequenceCubit>().toggleExplanation() : null,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ArrangeTheSequenceCubit, ArrangeTheSequenceState>(
      listenWhen: (previous, current) {
        // Only trigger when hasChecked changes from false to true
        return !previous.hasChecked && current.hasChecked;
      },
      listener: (context, state) {
        onAnswerChecked(state.isCorrect);
        _showResultOverlay(
          context,
          state.isCorrect ? ResultType.correct : ResultType.incorrect,
        );
      },
      child: BlocBuilder<ArrangeTheSequenceCubit, ArrangeTheSequenceState>(
        builder: (context, state) {
          final currentQuestion = state.question;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentQuestion.document.isNotEmpty) ...[
                DocumentWidget(documents: currentQuestion.document),
                12.verticalSpace,
              ],
              AppText(
                context.text.exercise.exerciseSequenceInstruction,
                margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                maxLines: 10,
                style: AppStyle.text12
                    .copyWith(
                      color: const Color(0xFF7F8EA4),
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    )
                    .copyWith(
                      color: const Color(0xFF7F8EA4).withValues(alpha: 0.6),
                    ),
              ),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                padding: EdgeInsets.symmetric(horizontal: 20.w),
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
                onReorder: (oldIndex, newIndex) {
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
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  /// Build the bottom button for arrange the sequence questions
  Widget buildBottomButton(BuildContext context) {
    return BlocBuilder<ArrangeTheSequenceCubit, ArrangeTheSequenceState>(
      builder: (context, state) {
        final canCheck = state.currentItems.isNotEmpty && !state.hasChecked;

        return ExerciseContinueButton(
          onPressed: canCheck ? () => context.read<ArrangeTheSequenceCubit>().checkAnswer() : null,
          text: 'Check',
          isEnabled: canCheck,
        );
      },
    );
  }
}
