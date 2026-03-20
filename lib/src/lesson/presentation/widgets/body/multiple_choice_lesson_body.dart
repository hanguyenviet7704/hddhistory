part of '../../../lesson.dart';

class MultipleChoiceLessonBody extends LessonBodyWidget {
  final Function(bool) onAnswerChecked;
  final bool isReadOnly;

  const MultipleChoiceLessonBody({
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
          BlocProvider.value(value: parentContext.read<ChoiceCubit>()),
          BlocProvider.value(value: parentContext.read<LessonCubit>()),
        ],
        child: BlocBuilder<ChoiceCubit, ChoiceState>(
          builder: (context, state) {
            final hasExplanation = state.question.hasExplanation;
            return ResultBottomSheet(
              type: type,
              showExplanation: state.showExplanation,
              explanationText: state.question.explanationText,
              onContinue: onContinue,
              onExplain: showExplainAction && hasExplanation ? () => context.read<ChoiceCubit>().toggleExplanation() : null,
            );
          },
        ),
      ),
    );
  }

  void _handleExplainTap(BuildContext context, QuestionEntity currentQuestion, ChoiceState state) {
    if (isReadOnly) {
      context.read<LessonCubit>().consumePendingAdvance();
    }
    if (currentQuestion.hasExplanation && !state.showExplanation) {
      context.read<ChoiceCubit>().toggleExplanation();
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
    return BlocListener<ChoiceCubit, ChoiceState>(
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
      child: BlocBuilder<ChoiceCubit, ChoiceState>(
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
                context.l10n.exercise.exerciseMultiChoicesInstruction,
                margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                maxLines: 10,
                style: AppStyle.text12.copyWith(
                  color: const Color(0xFF7F8EA4),
                  fontWeight: FontWeight.w500,
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.answerOptions.length,
                separatorBuilder: (context, index) => 12.verticalSpace,
                itemBuilder: (context, index) {
                  return MultipleChoiceAnswerCard(
                    option: state.answerOptions[index],
                    state: state.getAnswerState(index),
                    onTap: () => context.read<ChoiceCubit>().selectAnswer(index),
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
    return BlocBuilder<ChoiceCubit, ChoiceState>(
      builder: (context, state) {
        // if (state.hasChecked) {
        //   return const SizedBox.shrink();
        // }

        final canCheck = state.selectedAnswersIndices.isNotEmpty;

        return ExerciseContinueButton(
          onPressed: canCheck ? () => context.read<ChoiceCubit>().checkAnswer() : null,
          text: context.l10n.lesson.checkButton,
          isEnabled: canCheck,
        );
      },
    );
  }
}
