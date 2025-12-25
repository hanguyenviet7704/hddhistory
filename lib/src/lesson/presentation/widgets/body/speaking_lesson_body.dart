part of '../../../lesson.dart';

class SpeakingLessonBody extends StatelessWidget {
  final Function(bool) onAnswerChecked;

  const SpeakingLessonBody({
    super.key,
    required this.onAnswerChecked,
  });

  void _showResultOverlay(BuildContext context, ResultType type) {
    context.read<LessonCubit>().setIsShowResultOverlay(true);
    LessonResultOverlayManager.show(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<SpeakingCubit>(),
        child: SpeakingResultBottomSheet(
          type: type,
          onContinue: () {
            LessonResultOverlayManager.hide();
            AppDI.injector.get<ExerciseCubit>().nextQuestion();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SpeakingCubit, SpeakingState>(
      listenWhen: (previous, current) {
        // Trigger when submission status changes
        return previous.status != current.status;
      },
      listener: (context, state) {
        // Handle submission success
        if (state.status == SpeakingStatus.success) {
          // For speaking exercises, we don't check correct/incorrect immediately
          // Just move to the next question after successful submission
          onAnswerChecked(true);
          final bool isRoleplay = AppDI.injector.get<ExerciseCubit>().state.currentLearningItem.type == LearningItemType.roleplay;
          if (isRoleplay) return;
          _showResultOverlay(context, ResultType.correct);
          // AppDI.injector.get<ExerciseCubit>().nextQuestion();
        }
      },
      child: BlocBuilder<SpeakingCubit, SpeakingState>(
        builder: (context, state) {
          final currentQuestion = state.question;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display question document (images, audio, text, etc.)
              if (currentQuestion.document.isNotEmpty) ...[
                DocumentWidget(documents: currentQuestion.document),
                16.verticalSpace,
              ],
            ],
          );
        },
      ),
    );
  }

  /// Build the bottom button for speaking questions
  Widget buildBottomButton(BuildContext context) {
    return const SpeakingBottomAction();
  }
}
