part of '../../../lesson.dart';

class SpeakingLessonBody extends StatelessWidget {
  final Function(bool) onAnswerChecked;
  final VoidCallback? onRoleplayReplayTap;
  final bool isReadOnly;

  const SpeakingLessonBody({
    super.key,
    required this.onAnswerChecked,
    this.onRoleplayReplayTap,
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
          BlocProvider.value(value: context.read<SpeakingCubit>()),
          BlocProvider.value(value: context.read<LessonCubit>()),
        ],
        child: SpeakingResultBottomSheet(
          type: type,
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
        ),
      ),
    );
  }

  void _handleExplainTap(BuildContext context, bool hasExplainData, SpeakingState state) {
    if (isReadOnly) {
      context.read<LessonCubit>().consumePendingAdvance();
    }
    if (hasExplainData && !state.showExplanation) {
      context.read<SpeakingCubit>().toggleExplanation();
    }
    _showResultOverlay(context, ResultType.correct, isReview: isReadOnly);
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
          final isLessonExercise = context.select((ExerciseCubit bloc) => bloc.state.currentLearningItem.type == LearningItemType.exercise);
          final hasExplainData = state.textInput.isNotEmpty || state.goodPoints.isNotEmpty || state.improvementPoints.isNotEmpty || (state.audioFilePath?.isNotEmpty ?? false);
          final showExplainButton = isLessonExercise && state.status == SpeakingStatus.success && hasExplainData;

          final content = Column(
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
                onPlayTap: onRoleplayReplayTap,
              ),

              16.verticalSpace,
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IgnorePointer(ignoring: isReadOnly, child: content),
              if (showExplainButton) ...[
                12.verticalSpace,
                LessonExplainButton(
                  onTap: () => _handleExplainTap(context, hasExplainData, state),
                  hasExplanation: hasExplainData,
                ),
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

class _SpeakingAnswerCard extends StatelessWidget {
  final QuestionEntity question;
  final String? audioFilePath;
  final String textInput;
  final VoidCallback? onPlayTap;

  const _SpeakingAnswerCard({
    required this.question,
    required this.audioFilePath,
    required this.textInput,
    this.onPlayTap,
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
                ? AudioPlayerUrlWidget(audioUrl: normalizedRecordPath, onPlayTap: onPlayTap)
                : AudioPlayerFileWidget(filePath: normalizedRecordPath, onPlayTap: onPlayTap),
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
