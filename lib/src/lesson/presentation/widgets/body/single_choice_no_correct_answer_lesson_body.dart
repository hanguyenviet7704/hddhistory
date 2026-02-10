part of '../../../lesson.dart';

class SingleChoiceNoCorrectAnswerLessonBody extends StatelessWidget {
  final Function(bool) onAnswerChecked;
  final bool isReadOnly;

  const SingleChoiceNoCorrectAnswerLessonBody({
    super.key,
    required this.onAnswerChecked,
    this.isReadOnly = false,
  });

  void _showResultOverlay(
    BuildContext context,
    ResultType type, {
    bool isReview = false,
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
            return ResultBottomSheet(
              type: type,
              title: context.text.exercise.exerciseLessonCompleteTitle,
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
              onExplain: null,
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
        return !previous.hasChecked && current.hasChecked;
      },
      listener: (context, state) async {
        onAnswerChecked(state.isCorrect);
        final exerciseType = AppDI.injector.get<ExerciseCubit>().state.currentLearningItem.type;
        final bool isRoleplay = exerciseType == LearningItemType.roleplay;
        if (isRoleplay) return;

        if (exerciseType == LearningItemType.exercise) {
          final resolvedGroup = resolveNoCorrectAnswerDocumentGroup(
            question: state.question,
            selectedAnswerIndex: state.selectedAnswerIndex,
          );
          if (resolvedGroup != null) {
            await NoCorrectAnswerDocumentRoute(groupId: resolvedGroup.groupId).push(context);
            if (!context.mounted) return;
            AppDI.injector.get<ExerciseCubit>().nextQuestion();
            return;
          }
        }

        _showResultOverlay(
          context,
          state.isCorrect ? ResultType.correct : ResultType.incorrect,
        );
      },
      child: BlocBuilder<ChoiceCubit, ChoiceState>(
        builder: (context, state) {
          final bool isLessonExercise = context.select((ExerciseCubit bloc) => bloc.state.currentLearningItem.type == LearningItemType.exercise);
          final inlineDocumentGroup = isReadOnly && state.hasChecked && isLessonExercise
              ? resolveNoCorrectAnswerDocumentGroup(
                  question: state.question,
                  selectedAnswerIndex: state.selectedAnswerIndex,
                )
              : null;
          final hasInlineDocuments = inlineDocumentGroup != null && inlineDocumentGroup.documents.isNotEmpty;

          return IgnorePointer(
            ignoring: isReadOnly,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SingleChoiceQuestionContent(state: state),
                if (hasInlineDocuments) ...[
                  12.verticalSpace,
                  DocumentWidget(documents: inlineDocumentGroup.documents),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildBottomButton(BuildContext context) {
    return _buildSingleChoiceBottomButton(context);
  }
}
