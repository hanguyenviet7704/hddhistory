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

  bool get isCorrect => type == ResultType.correct;
  Color get backgroundColor => isCorrect ? const Color(0xFFEAFFEF) : const Color(0xFFFDEAE7);
  Color get buttonColor => isCorrect ? const Color(0xFF1DA75E) : const Color(0xFFE34646);
  Color get iconColor => isCorrect ? const Color(0xFF1DA75E) : const Color(0xFFE34646);
  String get title => isCorrect ? 'Correct answer!' : 'Incorrect';
  String get iconAsset => isCorrect ? AppAsset.icons.app.icTick.path : AppAsset.icons.app.icClose.path;

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
              // Slide up from bottom with fade
              final offsetAnimation = Tween<Offset>(
                begin: const Offset(0.0, 0.3), // Start from below
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
            child: showExplanation && explanationText.isNotEmpty
                ? _ArrangeSequenceExplanationContent(
                    key: const ValueKey('explanation'),
                    isCorrect: isCorrect,
                    arrangedAnswers: arrangedAnswers,
                    explanationText: explanationText,
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
                              title,
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
                                      AppAsset.svg.app.icBookOpen,
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

class _ArrangeSequenceExplanationContent extends StatelessWidget {
  final bool isCorrect;
  final List<OptionEntity> arrangedAnswers;
  final String explanationText;

  const _ArrangeSequenceExplanationContent({
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
          // "Correct answer" or "Incorrect" label
          AppText(
            isCorrect ? context.text.exerciseFeedbackCorrect : context.text.exerciseFeedbackIncorrect,
            style: AppStyle.textBold14.copyWith(
              color: isCorrect ? const Color(0xFF3A9377) : const Color(0xFFE34646),
              height: 1.75,
            ),
          ),
          4.verticalSpace,
          // Arranged answer cards
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
                    answer.text,
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
