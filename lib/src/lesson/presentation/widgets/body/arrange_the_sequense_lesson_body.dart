part of '../../../lesson.dart';

class ArrangeTheSequenceLessonBody extends LessonBodyWidget {
  final Function(bool) onAnswerChecked;
  final bool isReadOnly;

  const ArrangeTheSequenceLessonBody({
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
          BlocProvider.value(value: parentContext.read<ArrangeTheSequenceCubit>()),
          BlocProvider.value(value: parentContext.read<LessonCubit>()),
        ],
        child: BlocBuilder<ArrangeTheSequenceCubit, ArrangeTheSequenceState>(
          builder: (context, state) {
            final runtimeAnswers = questionRuntimeAnswers(state.question);
            final runtimeOptions = questionRuntimeOptions(state.question);
            final correctAnswers = runtimeAnswers.map((answer) {
              return runtimeOptions.firstWhere(
                (option) => option.id == answer.id,
                orElse: () => const OptionEntity(),
              );
            }).toList();
            final hasExplanation = state.question.hasExplanation;
            return ArrangeSequenceResultBottomSheet(
              type: type,
              showExplanation: state.showExplanation,
              explanationText: state.question.explanationText,
              arrangedAnswers: correctAnswers,
              onContinue: onContinue,
              onExplain: showExplainAction && hasExplanation ? () => context.read<ArrangeTheSequenceCubit>().toggleExplanation() : null,
            );
          },
        ),
      ),
    );
  }

  void _handleExplainTap(BuildContext context, QuestionEntity currentQuestion, ArrangeTheSequenceState state) {
    if (isReadOnly) {
      context.read<LessonCubit>().consumePendingAdvance();
    }
    if (currentQuestion.hasExplanation && !state.showExplanation) {
      context.read<ArrangeTheSequenceCubit>().toggleExplanation();
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
    return BlocListener<ArrangeTheSequenceCubit, ArrangeTheSequenceState>(
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
      child: BlocBuilder<ArrangeTheSequenceCubit, ArrangeTheSequenceState>(
        builder: (context, state) {
          final currentQuestion = state.question;
          final isLessonExercise = context.select((ExerciseCubit bloc) => bloc.state.currentLearningItem.type == LearningItemType.exercise);
          final showExplainButton = isLessonExercise && isReadOnly && currentQuestion.hasExplanation;

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentQuestion.document.isNotEmpty) ...[
                DocumentWidget(documents: currentQuestion.document),
                12.verticalSpace,
              ],
              AppText(
                context.l10n.exercise.exerciseSequenceInstruction,
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
}
