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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentQuestion.document.isNotEmpty) ...[
                ChoiceDocumentWidget(documents: currentQuestion.document),
                12.verticalSpace,
              ],
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
                    state: state.getAnswerState(index),
                    onTap: () => context.read<ChoiceCubit>().selectAnswer(index),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  /// Build the bottom button for single choice questions
  Widget buildBottomButton(BuildContext context) {
    return BlocBuilder<ChoiceCubit, ChoiceState>(
      builder: (context, state) {
        if (state.hasChecked) {
          return const SizedBox.shrink();
        }

        final canCheck = state.selectedAnswerIndex != -1;

        return ExerciseContinueButton(
          onPressed: canCheck ? () => context.read<ChoiceCubit>().checkAnswer() : null,
          text: 'Check',
          isEnabled: canCheck,
          showBorder: true,
        );
      },
    );
  }
}
