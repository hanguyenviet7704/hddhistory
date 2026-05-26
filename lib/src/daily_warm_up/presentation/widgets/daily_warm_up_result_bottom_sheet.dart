part of '../../daily_warm_up.dart';

class DailyWarmUpResultBottomSheet extends StatefulWidget {
  const DailyWarmUpResultBottomSheet({
    super.key,
    required this.result,
    required this.explanationText,
    required this.onContinue,
  });

  final DailyWarmUpAnswerResultEntity result;
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
      explanation: hasExplanation ? DailyWarmUpResultExplanationContent(explanationText: explanationText) : null,
      summary: DailyWarmUpResultSummary(
        type: isCorrect ? ResultType.correct : ResultType.incorrect,
        onContinue: widget.onContinue,
        onExplain: hasExplanation ? _toggleExplanation : null,
        showExplanation: explanationVisible,
        continueLabel: context.l10n.dailyWarmUp.continueButton,
        explainLabel: context.l10n.exercise.exerciseExplainButton,
        closeExplainLabel: context.l10n.exercise.exerciseCloseExplainButton,
        title: isNeutral ? context.l10n.dailyWarmUp.answerSaved : null,
        successAccentColor: isNeutral ? const Color(0xFF554FF0) : null,
        successBackgroundColor: isNeutral ? const Color(0xFFF2F1FE) : null,
      ),
    );
  }

  void _toggleExplanation() {
    setState(() => _showExplanation = !_showExplanation);
  }
}

class DailyWarmUpResultExplanationContent extends StatelessWidget {
  const DailyWarmUpResultExplanationContent({
    super.key,
    required this.explanationText,
  });

  final String explanationText;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('daily-warm-up-result-explanation'),
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            context.l10n.exercise.exerciseExplanationTitle,
            style: AppStyle.text20.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0D121C),
            ),
          ),
          16.verticalSpace,
          AppText(
            explanationText,
            maxLines: 100,
            style: AppStyle.text14.copyWith(
              color: const Color(0xFF364152),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
