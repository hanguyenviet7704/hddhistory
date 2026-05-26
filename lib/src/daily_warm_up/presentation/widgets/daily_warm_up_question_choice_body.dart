part of '../../daily_warm_up.dart';

class DailyWarmUpChoiceBody extends StatelessWidget {
  const DailyWarmUpChoiceBody({
    super.key,
    required this.state,
    required this.question,
    required this.onSelectChoice,
  });

  final DailyWarmUpState state;
  final QuestionEntity question;
  final ValueChanged<int> onSelectChoice;

  @override
  Widget build(BuildContext context) {
    final isMultiple = question.typedPayload is QuestionMultipleChoicePayloadEntity;
    final options = questionRuntimeOptions(question);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          _instructionText(context, question),
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
          itemCount: options.length,
          separatorBuilder: (context, index) => 12.verticalSpace,
          itemBuilder: (context, index) {
            final answerState = dailyWarmUpChoiceAnswerState(
              question: question,
              index: index,
              selectedAnswerIndex: state.selectedAnswerIndex,
              selectedAnswersIndices: state.selectedAnswersIndices,
              result: state.latestResult,
            );
            if (isMultiple) {
              return DailyWarmUpMultipleChoiceAnswerCard(
                option: options[index],
                state: answerState,
                onTap: () => onSelectChoice(index),
              );
            }
            return DailyWarmUpChoiceAnswerCard(
              option: options[index],
              state: answerState,
              onTap: () => onSelectChoice(index),
            );
          },
        ),
      ],
    );
  }

  String _instructionText(BuildContext context, QuestionEntity question) {
    return switch (question.typedPayload) {
      QuestionMultipleChoicePayloadEntity() => context.l10n.exercise.exerciseMultiChoicesInstruction,
      QuestionSingleChoiceNoCorrectAnswerPayloadEntity() => context.l10n.exercise.exerciseSingleChoiceNoCorrectAnswerInstruction,
      _ => context.l10n.exercise.exerciseSingleChoiceInstruction,
    };
  }
}
