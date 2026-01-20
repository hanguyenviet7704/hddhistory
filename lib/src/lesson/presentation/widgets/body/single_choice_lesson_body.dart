part of '../../../lesson.dart';

class SingleChoiceLessonBody extends StatelessWidget {
  final Function(bool) onAnswerChecked;
  final bool isReadOnly;

  const SingleChoiceLessonBody({
    super.key,
    required this.onAnswerChecked,
    this.isReadOnly = false,
  });

  void _showResultOverlay(BuildContext context, ResultType type, {bool isReview = false}) {
    final trackingData = KeypointTrackingData.fromContext();
    if (trackingData != null) {
      AppService.instance.appTrackingService.trackKeypointExerciseResultView(trackingData);
    }
    context.read<LessonCubit>().setIsShowResultOverlay(true);
    LessonResultOverlayManager.show(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: AppDI.injector.get<ChoiceCubit>()),
          BlocProvider.value(value: AppDI.injector.get<LessonCubit>()),
        ],
        child: BlocBuilder<ChoiceCubit, ChoiceState>(
          builder: (context, state) {
            final hasExplanation = state.question.explanation.text.isNotEmpty;

            return ResultBottomSheet(
              type: type,
              showExplanation: state.showExplanation,
              explanationText: state.question.explanation.text,
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
              onExplain: hasExplanation ? () => context.read<ChoiceCubit>().toggleExplanation() : null,
            );
          },
        ),
      ),
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
          final showExplainButton = isLessonExercise && state.hasChecked;

          void handleExplainTap() {
            if (isReadOnly) {
              context.read<LessonCubit>().consumePendingAdvance();
            }
            final hasExplanation = state.question.explanation.text.isNotEmpty;
            if (hasExplanation && !state.showExplanation) {
              context.read<ChoiceCubit>().toggleExplanation();
            }
            _showResultOverlay(
              context,
              state.isCorrect ? ResultType.correct : ResultType.incorrect,
              isReview: isReadOnly,
            );
          }

          final content = Column(
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
                itemCount: currentQuestion.options.length,
                separatorBuilder: (context, index) => 12.verticalSpace,
                itemBuilder: (context, index) {
                  return ChoiceAnswerCard(
                    option: currentQuestion.options[index],
                    isMultiChoice: false,
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
                LessonExplainButton(onTap: handleExplainTap),
              ],
            ],
          );
        },
      ),
    );
  }

  /// Build the bottom button for single choice questions
  Widget buildBottomButton(BuildContext context) {
    return BlocBuilder<ChoiceCubit, ChoiceState>(
      builder: (context, state) {
        // if (state.hasChecked) {
        //   return const SizedBox.shrink();
        // }

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
}
