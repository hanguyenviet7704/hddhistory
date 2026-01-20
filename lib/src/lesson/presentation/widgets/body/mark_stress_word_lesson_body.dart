part of '../../../lesson.dart';

class MarkStressWordLessonBody extends StatelessWidget {
  final Function(bool) onAnswerChecked;
  final bool isReadOnly;

  const MarkStressWordLessonBody({
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
          BlocProvider.value(value: AppDI.injector.get<MarkStressWordCubit>()),
          BlocProvider.value(value: AppDI.injector.get<LessonCubit>()),
        ],
        child: BlocBuilder<MarkStressWordCubit, MarkStressWordState>(
          builder: (context, state) {
            final hasExplanation = state.question.explanation.text.isNotEmpty;

            return MarkStressWordResultBottomSheet(
              type: type,
              showExplanation: state.showExplanation,
              explanationText: state.question.explanation.text,
              words: state.words,
              selectedIndices: state.selectedWordIndices,
              correctIndices: state.correctWordIndices,
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
              onExplain: hasExplanation ? () => context.read<MarkStressWordCubit>().toggleExplanation() : null,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MarkStressWordCubit, MarkStressWordState>(
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
      child: BlocBuilder<MarkStressWordCubit, MarkStressWordState>(
        builder: (context, state) {
          final currentQuestion = state.question;
          final words = state.words;
          final isLessonExercise = context.select((ExerciseCubit bloc) => bloc.state.currentLearningItem.type == LearningItemType.exercise);
          final showExplainButton = isLessonExercise && state.hasChecked;

          void handleExplainTap() {
            if (isReadOnly) {
              context.read<LessonCubit>().consumePendingAdvance();
            }
            final hasExplanation = state.question.explanation.text.isNotEmpty;
            if (hasExplanation && !state.showExplanation) {
              context.read<MarkStressWordCubit>().toggleExplanation();
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
              if (currentQuestion.document.any((document) => document.dataAvailable)) ...[
                DocumentWidget(documents: currentQuestion.document),
                12.verticalSpace,
              ],
              AppText(
                context.text.exercise.exerciseStressMarkInstruction,
                margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                maxLines: 10,
                style: AppStyle.text12.copyWith(
                  color: const Color(0xFF7F8EA4).withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
              12.verticalSpace,
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignOutside,
                      color: const Color(0xFFE3E8EF) /* Border-border-secondary */,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Wrap(
                  spacing: 2.w,
                  runSpacing: 6.h,

                  children: List.generate(
                    words.length,
                    (index) {
                      // Create a temporary OptionEntity for each word
                      final wordOption = OptionEntity(
                        id: index,
                        text: BaseMultiLanguage(en: words[index], vi: words[index], zh: words[index]),
                        value: BaseMultiLanguage(en: words[index], vi: words[index], zh: words[index]),
                      );

                      return MarkStressWordCard(
                        option: wordOption,
                        state: state.getWordState(index),
                        onTap: () => context.read<MarkStressWordCubit>().selectWord(index),
                      );
                    },
                  ),
                ),
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

  /// Build the bottom button for mark stress word questions
  Widget buildBottomButton(BuildContext context) {
    return BlocBuilder<MarkStressWordCubit, MarkStressWordState>(
      builder: (context, state) {
        final canCheck = state.selectedWordIndices.isNotEmpty && !state.hasChecked;

        return ExerciseContinueButton(
          onPressed: canCheck ? () => context.read<MarkStressWordCubit>().checkAnswer() : null,
          text: context.text.lesson.checkButton,
          isEnabled: canCheck,
        );
      },
    );
  }
}
