part of '../../../../roleplay.dart';

class RoleplayExerciseAnswerCard extends StatelessWidget {
  final QuestionEntity exercise;

  const RoleplayExerciseAnswerCard({
    super.key,
    required this.exercise,
  });

  TextStyle get _questionTextStyle => AppStyle.text14.copyWith(
    color: AppCustomColor.textSecondary,
    fontWeight: FontWeight.w700,
    height: 1.75,
  );

  TextStyle get _labelTextStyle => AppStyle.text12.copyWith(
    color: AppCustomColor.textTertiary,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  TextStyle get _answerTextStyle => AppStyle.text14.copyWith(
    color: AppCustomColor.textPrimary,
    fontWeight: FontWeight.w500,
    height: 1.75,
  );

  bool get _showsStatusHeader => exercise.type != QuestionTypeEnum.speaking;

  String get _answerLabel => exercise.type == QuestionTypeEnum.speaking ? t.exercise.exerciseYourAnswer : t.exercise.exerciseAnswer;

  @override
  Widget build(BuildContext context) {
    final result = exercise.result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppCustomColor.roleplayAnswerBackground,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RoleplayExerciseAnswerHeader(
                exercise: exercise,
                showsStatusHeader: _showsStatusHeader,
                isCorrect: result.isCorrect,
                questionTextStyle: _questionTextStyle,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(8.w, 12.h, 8.w, 8.h),
                child: _RoleplayExerciseAnswerBody(
                  exercise: exercise,
                  result: result,
                  labelTextStyle: _labelTextStyle,
                  answerTextStyle: _answerTextStyle,
                  answerLabel: _answerLabel,
                ),
              ),
            ],
          ),
        ),
        if (exercise.explanation.text.isNotEmpty) ...[
          12.verticalSpace,
          _RoleplayExerciseExplanationSection(explanationText: exercise.explanation.text),
          12.verticalSpace,
        ],
      ],
    );
  }
}
