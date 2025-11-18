part of '../../../../lesson.dart';

class ArrangeSequenceResultBottomSheet extends StatelessWidget {
  final ResultType type;
  final VoidCallback onContinue;
  final VoidCallback? onExplain;
  final bool showExplanation;
  final String explanationText;
  final List<OptionEntity> arrangedAnswers;

  const ArrangeSequenceResultBottomSheet({
    super.key,
    required this.type,
    required this.onContinue,
    this.onExplain,
    this.showExplanation = false,
    this.explanationText = '',
    required this.arrangedAnswers,
  });

  @override
  Widget build(BuildContext context) {
    final hasExplanation = explanationText.isNotEmpty;
    final explanationVisible = hasExplanation && showExplanation;

    return LessonResultOverlay(
      showExplanation: explanationVisible,
      // onBackdropTap: explanationVisible ? onExplain : null,
      explanation: hasExplanation
          ? ArrangeSequenceExplanationContent(
              isCorrect: type == ResultType.correct,
              arrangedAnswers: arrangedAnswers,
              explanationText: explanationText,
            )
          : null,
      summary: ExerciseResultSummary(
        type: type,
        onContinue: onContinue,
        onExplain: hasExplanation ? onExplain : null,
        showExplanation: explanationVisible,
        continueLabel: context.text.onboardingSkipGreetingButton,
        explainLabel: context.text.exerciseExplainButton,
        closeExplainLabel: context.text.exerciseCloseExplainButton,
      ),
    );
  }
}

class ArrangeSequenceExplanationContent extends StatelessWidget {
  final bool isCorrect;
  final List<OptionEntity> arrangedAnswers;
  final String explanationText;

  const ArrangeSequenceExplanationContent({
    super.key,
    required this.isCorrect,
    required this.arrangedAnswers,
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
            isCorrect ? context.text.exerciseFeedbackCorrect : context.text.exerciseFeedbackIncorrect,
            style: AppStyle.textBold14.copyWith(
              color: isCorrect ? const Color(0xFF3A9377) : const Color(0xFFE34646),
              height: 1.75,
            ),
          ),
          4.verticalSpace,
          Column(
            children: arrangedAnswers.asMap().entries.map((entry) {
              final answer = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFFE3E8EF),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: AppText(
                    answer.text.text,
                    maxLines: 10,
                    style: AppStyle.text14.copyWith(
                      color: const Color(0xFF364152),
                      height: 1.75,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF8FF),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      AppAsset.svg.app.icTennisRacket,
                      width: 20.w,
                      height: 20.w,
                    ),
                    6.horizontalSpace,
                    AppText(
                      context.text.exerciseExplanationTitle,
                      style: AppStyle.textBold14.copyWith(
                        color: const Color(0xFF175CD3),
                        height: 1.75,
                      ),
                    ),
                  ],
                ),
                8.verticalSpace,
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
          ),
        ],
      ),
    );
  }
}
