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

              _SpeakingAnswerCard(
                question: currentQuestion,
                audioFilePath: state.audioFilePath,
                textInput: state.textInput,
              ),

              16.verticalSpace,
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

class _SpeakingAnswerCard extends StatelessWidget {
  final QuestionEntity question;
  final String? audioFilePath;
  final String textInput;

  const _SpeakingAnswerCard({
    required this.question,
    required this.audioFilePath,
    required this.textInput,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ExerciseCubit, ExerciseState, bool>(
      selector: (state) => state.currentLearningItem.type == LearningItemType.roleplay,
      builder: (context, isRoleplay) {
        if (!isRoleplay) return const SizedBox.shrink();
        final resultRecordPath = question.result.recordAnswer.record.trim();
        final fallbackRecordPath = audioFilePath?.trim() ?? '';
        final recordPath = resultRecordPath.isNotEmpty ? resultRecordPath : fallbackRecordPath;

        final resultReviewText = question.result.recordAnswer.review.trim();
        final fallbackReviewText = textInput.trim();
        final reviewText = resultReviewText.isNotEmpty ? resultReviewText : fallbackReviewText;

        if (recordPath.isNotEmpty) {
          final normalizedRecordPath = recordPath.startsWith('//') ? 'https:$recordPath' : recordPath;
          final isRemoteAudio = normalizedRecordPath.startsWith('http://') || normalizedRecordPath.startsWith('https://');
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: isRemoteAudio
                ? AudioPlayerUrlWidget(audioUrl: normalizedRecordPath)
                : AudioPlayerFileWidget(filePath: normalizedRecordPath),
          );
        }

        if (reviewText.isNotEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: AppText(
              reviewText,
              maxLines: 8,
              overflow: TextOverflow.visible,
              style: AppStyle.text14,
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
