part of '../../daily_warm_up.dart';

class DailyWarmUpResultBottomSheet extends StatefulWidget {
  const DailyWarmUpResultBottomSheet({
    super.key,
    required this.result,
    required this.question,
    required this.explanationText,
    required this.onContinue,
  });

  final DailyWarmUpAnswerResultEntity result;
  final QuestionEntity? question;
  final String explanationText;
  final VoidCallback onContinue;

  @override
  State<DailyWarmUpResultBottomSheet> createState() => _DailyWarmUpResultBottomSheetState();
}

class _DailyWarmUpResultBottomSheetState extends State<DailyWarmUpResultBottomSheet> {
  bool _showExplanation = false;

  @override
  Widget build(BuildContext context) {
    final isNeutral = widget.result.type == DailyWarmUpAnswerResultType.neutral;
    final isCorrect = widget.result.isCorrect;
    final explanationText = widget.explanationText.trim();
    final hasExplanation = explanationText.isNotEmpty;
    final explanationVisible = hasExplanation && _showExplanation;

    return LessonResultOverlay(
      showExplanation: explanationVisible,
      explanation: hasExplanation
          ? DailyWarmUpResultExplanationContent(
              result: widget.result,
              question: widget.question,
              explanationText: explanationText,
            )
          : null,
      summary: DailyWarmUpResultSummary(
        type: isCorrect ? ResultType.correct : ResultType.incorrect,
        onContinue: widget.onContinue,
        onExplain: hasExplanation ? _toggleExplanation : null,
        showExplanation: explanationVisible,
        continueLabel: context.l10n.dailyWarmUp.continueButton,
        explainLabel: context.l10n.exercise.exerciseExplainButton,
        closeExplainLabel: context.l10n.exercise.exerciseCloseExplainButton,
        title: isNeutral ? context.l10n.dailyWarmUp.answerSaved : null,
        successAccentColor: isNeutral ? const Color(0xFFB5860F) : null,
        successBackgroundColor: isNeutral ? const Color(0xFFFEFAF1) : null,
      ),
    );
  }

  void _toggleExplanation() {
    setState(() => _showExplanation = !_showExplanation);
  }
}
