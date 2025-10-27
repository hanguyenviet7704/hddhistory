part of '../../../exercise.dart';

class SingleChoiceLessonBody extends StatelessWidget {
  final Function(bool) onAnswerChecked;

  const SingleChoiceLessonBody({
    super.key,
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
          final currentQuestion = state.question;
          final canCheck = state.selectedAnswer != null && !state.hasChecked;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentQuestion.document.isNotEmpty) ...[
                ChoiceDocumentWidget(documents: currentQuestion.document),
                12.verticalSpace,
              ],
              // if (currentQuestion.hasAudio) ...[
              //   AudioPlayerWidget(audioUrl: currentQuestion.audioUrl),
              //   12.verticalSpace,
              // ],
              AppText(
                // currentQuestion.explanation,
                'Select the best answer',
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
                    state: _getAnswerState(currentQuestion.options[index], state),
                    onTap: () => context.read<ChoiceCubit>().selectAnswer(currentQuestion.options[index]),
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

  AnswerState _getAnswerState(OptionEntity option, ChoiceState state) {
    if (!state.hasChecked) {
      return state.selectedAnswer == option ? AnswerState.selected : AnswerState.normal;
    }

    if (state.question.id == 0) return AnswerState.normal;

    if (state.correctOptions.any((option) => option.id == option.id)) {
      return AnswerState.correct;
    } else if (state.selectedAnswer == option) {
      return AnswerState.incorrect;
    } else {
      return AnswerState.disabled;
    }
  }
}
