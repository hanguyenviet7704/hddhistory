part of '../../../../lesson.dart';

class CuesPlacementResultBottomSheet extends StatelessWidget {
  final ResultType type;
  final VoidCallback onContinue;
  final VoidCallback? onExplain;
  final bool showExplanation;
  final String? explanationText;
  final List<String> words;
  final Map<int, int> placedMarks; // word index -> option id
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
  Color get backgroundColor => isCorrect ? const Color(0xFFEAFFEF) : const Color(0xFFFDEAE7);
  Color get buttonColor => isCorrect ? const Color(0xFF41AE8C) : const Color(0xFFE34646);
  Color get iconColor => isCorrect ? const Color(0xFF41AE8C) : const Color(0xFFE34646);
  String title(BuildContext context) => isCorrect ? context.text.exerciseFeedbackCorrect : context.text.exerciseFeedbackIncorrect;
  String get iconAsset => isCorrect ? AppAsset.icons.app.icTick.path : AppAsset.icons.app.icClose.path;

  /// Build sentence with pause marks showing correct answer positions
  List<InlineSpan> _buildSentenceWithMarks() {
    final spans = <InlineSpan>[];

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final shouldHaveMark = correctPositions.contains(i);

      // Add word
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

      // Add pause mark if this position should have one
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

      // Add space between words (except after last word)
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
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.sp)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final offsetAnimation =
                  Tween<Offset>(
                    begin: const Offset(0.0, 0.3),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  );

              return SlideTransition(
                position: offsetAnimation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: showExplanation && explanationText != null
                ? _CuesPlacementExplanationContent(
                    key: const ValueKey('explanation'),
                    isCorrect: isCorrect,
                    sentenceSpans: _buildSentenceWithMarks(),
                    explanationText: explanationText!,
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: backgroundColor,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Image.asset(iconAsset, width: 24.w, height: 24.w),
                          8.horizontalSpace,
                          Expanded(
                            child: AppText(
                              title(context),
                              style: AppStyle.text16.copyWith(
                                color: iconColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onExplain != null)
                      Opacity(
                        opacity: 0.5,
                        child: GestureDetector(
                          onTap: onExplain,
                          child: Row(
                            children: [
                              (showExplanation)
                                  ? Icon(Icons.close_rounded, color: const Color(0xFF0D121C), size: 20.w)
                                  : SvgPicture.asset(
                                      AppAsset.svg.app.icBook,
                                      width: 20.w,
                                      height: 20.w,
                                    ),
                              8.horizontalSpace,
                              AppText(
                                showExplanation ? context.text.exerciseCloseExplainButton : context.text.exerciseExplainButton,
                                style: AppStyle.text14.copyWith(
                                  color: const Color(0xFF0D121C),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                16.verticalSpace,
                SizedBox(
                  width: double.infinity,
                  height: 54.h,
                  child: ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(1000.r),
                      ),
                    ),
                    child: AppText(
                      context.text.onboardingSkipGreetingButton,
                      style: AppStyle.text16.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColorLight.surface,
                      ),
                    ),
                  ),
                ),
                16.verticalSpace,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CuesPlacementExplanationContent extends StatelessWidget {
  final bool isCorrect;
  final List<InlineSpan> sentenceSpans;
  final String explanationText;

  const _CuesPlacementExplanationContent({
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
          // "Correct answer" label
          AppText(
            context.text.exerciseFeedbackCorrectAnswer,
            style: AppStyle.textBold14.copyWith(
              color: const Color(0xFF3A9377),
              height: 1.75,
            ),
          ),
          4.verticalSpace,
          // Sentence with pause marks
          RichText(
            text: TextSpan(
              children: sentenceSpans,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
          16.verticalSpace,
          // Divider line
          Container(
            height: 1,
            width: double.infinity,
            color: const Color(0xFFE3E8EF),
          ),
          16.verticalSpace,
          // Explanation box
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
                // Tag with icon
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
                // Explanation text
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
