part of '../../../../lesson.dart';

class ResultBottomSheet extends StatelessWidget {
  final ResultType type;
  final VoidCallback onContinue;
  final VoidCallback? onExplain;
  final bool showExplanation;
  final String? explanationText;
  final String? title;

  const ResultBottomSheet({
    super.key,
    required this.type,
    required this.onContinue,
    this.onExplain,
    this.showExplanation = false,
    this.explanationText,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final hasExplanation = (explanationText ?? '').isNotEmpty;
    final explanationVisible = hasExplanation && showExplanation;

    return LessonResultOverlay(
      showExplanation: explanationVisible,
      // onBackdropTap: explanationVisible ? onExplain : null,
      explanation: hasExplanation ? ChoiceExplanationContent(explanationText: explanationText!) : null,
      summary: ExerciseResultSummary(
        type: type,
        onContinue: onContinue,
        onExplain: hasExplanation ? onExplain : null,
        showExplanation: explanationVisible,
        continueLabel: context.l10n.onboarding.onboardingSkipGreetingButton,
        explainLabel: context.l10n.exercise.exerciseExplainButton,
        closeExplainLabel: context.l10n.exercise.exerciseCloseExplainButton,
        title: title,
      ),
    );
  }
}

class ChoiceExplanationContent extends StatelessWidget {
  final String explanationText;

  const ChoiceExplanationContent({
    super.key,
    required this.explanationText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
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
