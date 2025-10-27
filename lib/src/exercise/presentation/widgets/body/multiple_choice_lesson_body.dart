part of '../../../exercise.dart';

class MultipleChoiceLessonBody extends StatelessWidget {
  final ChoiceQuestion question;
  final Function(bool) onAnswerChecked;

  const MultipleChoiceLessonBody({
    super.key,
    required this.question,
    required this.onAnswerChecked,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppDI.injector<ChoiceCubit>()..loadQuestion(question),
      child: _MultipleChoiceLessonBodyView(
        onAnswerChecked: onAnswerChecked,
      ),
    );
  }

  /// Build the bottom button for multiple choice questions
  Widget buildBottomButton(BuildContext context) {
    return BlocBuilder<ChoiceCubit, ChoiceState>(
      builder: (context, state) {
        if (state.hasChecked) {
          return const SizedBox.shrink();
        }

        final canCheck = state.selectedAnswersIndices.isNotEmpty;

        return ExerciseContinueButton(
          onPressed: canCheck ? () => context.read<ChoiceCubit>().checkAnswer() : null,
          text: 'Check',
          isEnabled: canCheck,
        );
      },
    );
  }
}

class _MultipleChoiceLessonBodyView extends StatelessWidget {
  final Function(bool) onAnswerChecked;

  const _MultipleChoiceLessonBodyView({
    required this.onAnswerChecked,
  });

  void _showResultBottomSheet(BuildContext context, ResultType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      routeSettings: const RouteSettings(name: RouteNamed.exerciseResultPopup),
      builder: (modalContext) => BlocProvider.value(
        value: context.read<ChoiceCubit>(),
        child: BlocBuilder<ChoiceCubit, ChoiceState>(
          bloc: context.read<ChoiceCubit>(),
          builder: (context, state) {
            return Stack(
              children: [
                // Animated backdrop overlay
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  opacity: state.showExplanation ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: !state.showExplanation,
                    child: GestureDetector(
                      onTap: () => context.read<ChoiceCubit>().toggleExplanation(),
                      child: Container(
                        color: const Color(0xFF364152).withAlpha((0.6 * 255).round()),
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                ),
                // Result bottom sheet
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ResultBottomSheet(
                    type: type,
                    showExplanation: state.showExplanation,
                    explanationText: state.question.explanation,
                    onContinue: () {
                      modalContext.back();
                    },
                    onExplain: () {
                      context.read<ChoiceCubit>().toggleExplanation();
                    },
                  ),
                ),
              ],
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
        _showResultBottomSheet(
          context,
          state.isCorrect ? ResultType.correct : ResultType.incorrect,
        );
      },
      child: BlocBuilder<ChoiceCubit, ChoiceState>(
        builder: (context, state) {
          final currentQuestion = state.question;
          if (currentQuestion.id == 0) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // if (currentQuestion.hasImage && currentQuestion.imageUrl != null) ...[
              //   ImageCard(imageUrl: currentQuestion.imageUrl),
              //   12.verticalSpace,
              // ],
              // if (currentQuestion.hasAudio) ...[
              //   AudioPlayerWidget(audioUrl: currentQuestion.audioUrl),
              //   12.verticalSpace,
              // ],
              // Padding(
              //   padding: EdgeInsets.only(top: 16.h, bottom: 8.h),
              //   child: AppText(
              //     currentQuestion.instructionText,
              //     style: AppStyle.text12.copyWith(
              //       color: const Color(0xFF7F8EA4),
              //       fontWeight: FontWeight.w500,
              //     ),
              //   ),
              // ),
              // ListView.separated(
              //   shrinkWrap: true,
              //   physics: const NeverScrollableScrollPhysics(),
              //   itemCount: currentQuestion.answers.length,
              //   separatorBuilder: (context, index) => 12.verticalSpace,
              //   itemBuilder: (context, index) {
              //     return ChoiceAnswerCard(
              //       text: currentQuestion.answers[index],
              //       isMultiChoice: true,
              //       state: _getAnswerState(index, state),
              //       onTap: () => context.read<ChoiceCubit>().selectAnswer(index),
              //     );
              //   },
              // ),
            ],
          );
        },
      ),
    );
  }

  // AnswerState _getAnswerState(int index, ChoiceState state) {
  //   if (!state.hasChecked) {
  //     return state.selectedAnswers.contains(index) ? AnswerState.selected : AnswerState.normal;
  //   }

  //   if (state.currentQuestion == null) return AnswerState.normal;

  //   final correctSet = state.currentQuestion!.correctAnswersIndices ?? {};
  //   if (correctSet.contains(index)) {
  //     return state.selectedAnswers.contains(index) ? AnswerState.correct : AnswerState.disabled;
  //   } else if (state.selectedAnswers.contains(index)) {
  //     return AnswerState.incorrect;
  //   } else {
  //     return AnswerState.disabled;
  //   }
  // }
}
