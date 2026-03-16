part of '../../../lesson.dart';

class SingleChoiceNoCorrectAnswerLessonBody extends LessonBodyWidget {
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
            return ResultBottomSheet(
              type: type,
              title: context.l10n.exercise.exerciseLessonCompleteTitle,
              showExplanation: state.showExplanation,
              explanationText: state.question.explanationText,
              onContinue: onContinue,
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

  @override
  Widget buildBottomButton(BuildContext context) {
    return _buildSingleChoiceBottomButton(context);
  }
}
