part of '../../../../lesson.dart';

class CuesPlacementResultBottomSheet extends StatelessWidget {
  final ResultType type;
  final VoidCallback onContinue;
  final VoidCallback? onExplain;
  final bool showExplanation;
  final String? explanationText;
  final List<String> words;
  final Map<int, int> placedMarks;
  final Set<int> correctPositions;
  final Map<int, OptionEntity> optionsById;

  const CuesPlacementResultBottomSheet({
    super.key,
    required this.type,
    required this.onContinue,
    this.onExplain,
    this.showExplanation = false,
    this.explanationText,
    required this.words,
    required this.placedMarks,
    required this.correctPositions,
    required this.optionsById,
  });

  bool get isCorrect => type == ResultType.correct;

  List<InlineSpan> _buildSentenceWithMarks() {
    final spans = <InlineSpan>[];

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final shouldHaveMark = correctPositions.contains(i);

      spans.add(
        TextSpan(
          text: word,
          style: TextStyle(
            color: shouldHaveMark ? const Color(0xFF0D121C) : const Color(0xFF7F8EA4),
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
      );

      if (shouldHaveMark) {
        spans.add(
          TextSpan(
            text: ' (pause)',
            style: TextStyle(
              color: const Color(0xFF0D121C),
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        );
      }

      if (i < words.length - 1) {
        spans.add(
          TextSpan(
            text: ' ',
            style: TextStyle(
              fontSize: 16.sp,
              height: 1.5,
            ),
          ),
        );
      }
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final hasExplanation = (explanationText ?? '').isNotEmpty;
    final explanationVisible = hasExplanation && showExplanation;

    return LessonResultOverlay(
      showExplanation: explanationVisible,
      onBackdropTap: explanationVisible ? onExplain : null,
      explanation: hasExplanation
          ? CuesPlacementExplanationContent(
              isCorrect: isCorrect,
              sentenceSpans: _buildSentenceWithMarks(),
              explanationText: explanationText!,
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
        successAccentColor: const Color(0xFF41AE8C),
      ),
    );
  }
}

class CuesPlacementExplanationContent extends StatelessWidget {
  final bool isCorrect;
  final List<InlineSpan> sentenceSpans;
  final String explanationText;

  const CuesPlacementExplanationContent({
    super.key,
    required this.isCorrect,
    required this.sentenceSpans,
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
            context.text.exerciseFeedbackCorrectAnswer,
            style: AppStyle.textBold14.copyWith(
              color: const Color(0xFF3A9377),
              height: 1.75,
            ),
          ),
          4.verticalSpace,
          RichText(
            text: TextSpan(
              children: sentenceSpans,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
          16.verticalSpace,
          Container(
            height: 1,
            width: double.infinity,
            color: const Color(0xFFE3E8EF),
          ),
          16.verticalSpace,
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
