part of '../../../lesson.dart';

class SingleChoiceLessonBody extends StatelessWidget {
  final Function(bool) onAnswerChecked;
  final bool isReadOnly;

  const SingleChoiceLessonBody({
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
    final trackingData = KeypointTrackingData.fromContext();
    if (trackingData != null) {
      AppService.instance.appTrackingService.trackKeypointExerciseResultView(trackingData);
    }
    context.read<LessonCubit>().setIsShowResultOverlay(true);
    LessonResultOverlayManager.show(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<ChoiceCubit>()),
          BlocProvider.value(value: context.read<LessonCubit>()),
        ],
        child: BlocBuilder<ChoiceCubit, ChoiceState>(
          builder: (context, state) {
            final hasExplanation = state.question.hasExplanation;

            return ResultBottomSheet(
              type: type,
              showExplanation: state.showExplanation,
              explanationText: state.question.explanationText,
              onContinue: () {
                if (isReview) {
                  LessonResultOverlayManager.hide();
                  context.read<LessonCubit>().setIsShowResultOverlay(false);
                  return;
                }
                if (trackingData != null) {
                  AppService.instance.appTrackingService.trackKeypointExerciseContinue(trackingData);
                }
                LessonResultOverlayManager.hide();
                AppDI.injector.get<ExerciseCubit>().nextQuestion();
              },
              onExplain: showExplainAction && hasExplanation
                  ? () {
                      context.read<ChoiceCubit>().toggleExplanation();
                    }
                  : null,
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
        final exerciseType = AppDI.injector.get<ExerciseCubit>().state.currentLearningItem.type;
        final bool isRoleplay = exerciseType == LearningItemType.roleplay;
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IgnorePointer(
                ignoring: isReadOnly,
                child: _SingleChoiceQuestionContent(state: state),
              ),
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

  /// Build the bottom button for single choice questions
  Widget buildBottomButton(BuildContext context) {
    return _buildSingleChoiceBottomButton(context);
  }
}

class _SingleChoiceQuestionContent extends StatelessWidget {
  final ChoiceState state;

  const _SingleChoiceQuestionContent({
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final currentQuestion = state.question;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (currentQuestion.document.isNotEmpty) ...[
          DocumentWidget(documents: currentQuestion.document),
          12.verticalSpace,
        ],
        AppText(
          context.text.exercise.exerciseSingleChoiceInstruction,
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
            return ChoiceAnswerCard(
              option: state.answerOptions[index],
              isMultiChoice: false,
              state: state.getAnswerState(index),
              onTap: () => context.read<ChoiceCubit>().selectAnswer(index),
            );
          },
        ),
      ],
    );
  }
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
        text: context.text.lesson.checkButton,
        isEnabled: canCheck,
      );
    },
  );
}
