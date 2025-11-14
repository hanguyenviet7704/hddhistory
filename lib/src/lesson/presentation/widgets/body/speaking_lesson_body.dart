part of '../../../lesson.dart';

class SpeakingLessonBody extends StatelessWidget {
  final Function(bool) onAnswerChecked;

  const SpeakingLessonBody({
    super.key,
    required this.onAnswerChecked,
  });

  void _showResultOverlay(BuildContext context, ResultType type) {
    LessonResultOverlayManager.show(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<SpeakingCubit>(),
        child: BlocBuilder<SpeakingCubit, SpeakingState>(
          builder: (context, state) {
            final hasExplanation = state.question.explanation.isNotEmpty;

            return SpeakingResultBottomSheet(
              type: type,
              showExplanation: state.showExplanation,
              analysisText: state.question.explanation,
              onContinue: () {
                LessonResultOverlayManager.hide();
                AppDI.injector.get<ExerciseCubit>().nextQuestion();
              },
              onExplain: hasExplanation ? () => context.read<SpeakingCubit>().toggleExplanation() : null,
              audioFilePath: state.audioFilePath,
              goodPoints: const [
                'Paraphrasing means restating',
                'what the other person has said in your own words',
              ],
              improvementPoints: const [
                'Try to use more varied vocabulary',
                'Improve pronunciation clarity',
              ],
            );
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
          _showResultOverlay(context, ResultType.correct);
          // AppDI.injector.get<ExerciseCubit>().nextQuestion();
        }

        // Handle submission failure
        if (state.status == SpeakingStatus.failure && state.errorMessage != null) {
          // Show error message using EasyLoading or SnackBar
          EasyLoading.showError(state.errorMessage!);
          _showResultOverlay(context, ResultType.incorrect);
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
