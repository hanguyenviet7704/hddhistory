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
      builder: (context) => ResultBottomSheet(
        type: type,
        onContinue: () {
          Navigator.of(context).pop();
        },
        onExplain: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChoiceCubit, ChoiceState>(
      listener: (context, state) {
        if (state.hasChecked) {
          onAnswerChecked(state.isCorrect);
          _showResultBottomSheet(
            context,
            state.isCorrect ? ResultType.correct : ResultType.incorrect,
          );
        }
      },
      child: BlocBuilder<ChoiceCubit, ChoiceState>(
        builder: (context, state) {
          final currentQuestion = state.currentQuestion;
          if (currentQuestion == null) return const SizedBox.shrink();

          final canCheck = state.selectedAnswers.isNotEmpty && !state.hasChecked;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentQuestion.hasImage && currentQuestion.imageUrl != null) ...[
                ImageCard(imageUrl: currentQuestion.imageUrl),
                12.verticalSpace,
              ],
              if (currentQuestion.hasAudio) ...[
                AudioPlayerWidget(audioUrl: currentQuestion.audioUrl),
                12.verticalSpace,
              ],
              Padding(
                padding: EdgeInsets.only(top: 16.h, bottom: 8.h),
                child: AppText(
                  currentQuestion.instructionText,
                  style: AppStyle.text12.copyWith(
                    color: const Color(0xFF7F8EA4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: currentQuestion.answers.length,
                separatorBuilder: (context, index) => 12.verticalSpace,
                itemBuilder: (context, index) {
                  return ChoiceAnswerCard(
                    text: currentQuestion.answers[index],
                    isMultiChoice: true,
                    state: _getAnswerState(index, state),
                    onTap: () => context.read<ChoiceCubit>().selectAnswer(index),
                  );
                },
              ),
              20.verticalSpace,
              if (!state.hasChecked)
                ExerciseContinueButton(
                  onPressed: canCheck ? () => context.read<ChoiceCubit>().checkAnswer() : null,
                  text: 'Check',
                  isEnabled: canCheck,
                  showBorder: true,
                ),
            ],
          );
        },
      ),
    );
  }

  AnswerState _getAnswerState(int index, ChoiceState state) {
    if (!state.hasChecked) {
      return state.selectedAnswers.contains(index) ? AnswerState.selected : AnswerState.normal;
    }

    if (state.currentQuestion == null) return AnswerState.normal;

    final correctSet = state.currentQuestion!.correctAnswersIndices ?? {};
    if (correctSet.contains(index)) {
      return state.selectedAnswers.contains(index) ? AnswerState.correct : AnswerState.disabled;
    } else if (state.selectedAnswers.contains(index)) {
      return AnswerState.incorrect;
    } else {
      return AnswerState.disabled;
    }
  }
}
