part of '../../daily_warm_up.dart';

class DailyWarmUpResultBottomSheet extends StatelessWidget {
  const DailyWarmUpResultBottomSheet({
    super.key,
    required this.result,
    required this.onContinue,
  });

  final DailyWarmUpAnswerResultEntity result;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final isNeutral = result.type == DailyWarmUpAnswerResultType.neutral;
    final isCorrect = result.isCorrect;

    return LessonResultOverlay(
      summary: ExerciseResultSummary(
        type: isCorrect ? ResultType.correct : ResultType.incorrect,
        onContinue: onContinue,
        continueLabel: context.l10n.dailyWarmUp.continueButton,
        explainLabel: context.l10n.exercise.exerciseExplainButton,
        closeExplainLabel: context.l10n.exercise.exerciseCloseExplainButton,
        title: isNeutral ? context.l10n.dailyWarmUp.answerSaved : null,
        successAccentColor: isNeutral ? const Color(0xFF554FF0) : null,
        successBackgroundColor: isNeutral ? const Color(0xFFF2F1FE) : null,
      ),
    );
  }
}
