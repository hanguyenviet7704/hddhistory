part of '../../../../lesson.dart';

class SpeakingResultBottomSheet extends StatelessWidget {
  final ResultType type;
  final VoidCallback onContinue;
  final VoidCallback? onExplain;
  final bool showExplanation;
  final String? analysisText;
  final String? audioFilePath;
  final List<String>? goodPoints;
  final List<String>? improvementPoints;

  const SpeakingResultBottomSheet({
    super.key,
    required this.type,
    required this.onContinue,
    this.onExplain,
    this.showExplanation = false,
    this.analysisText,
    this.audioFilePath,
    this.goodPoints,
    this.improvementPoints,
  });

  bool get isCorrect => type == ResultType.correct;
  Color get backgroundColor => isCorrect ? const Color(0xFFEAFFEF) : const Color(0xFFFDEAE7);
  Color get buttonColor => isCorrect ? const Color(0xFF1DA75E) : const Color(0xFFE34646);
  Color get iconColor => isCorrect ? const Color(0xFF1DA75E) : const Color(0xFFE34646);
  String title(BuildContext context) =>
      isCorrect ? context.text.exerciseFeedbackCorrect : context.text.exerciseFeedbackIncorrect;
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
              final offsetAnimation = Tween<Offset>(
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
            child: showExplanation && analysisText != null
                ? _SpeakingExplanationContent(
                    key: const ValueKey('explanation'),
                    isCorrect: isCorrect,
                    analysisText: analysisText!,
                    audioFilePath: audioFilePath,
                    goodPoints: goodPoints ?? [],
                    improvementPoints: improvementPoints ?? [],
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
                              isCorrect && showExplanation
                                  ? 'Completed!'
                                  : title(context),
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
                                  ? Icon(Icons.close_rounded,
                                      color: const Color(0xFF0D121C), size: 20.w)
                                  : SvgPicture.asset(
                                      AppAsset.svg.app.icBook,
                                      width: 20.w,
                                      height: 20.w,
                                    ),
                              8.horizontalSpace,
                              AppText(
                                showExplanation
                                    ? context.text.exerciseCloseExplainButton
                                    : context.text.exerciseExplainButton,
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

class _SpeakingExplanationContent extends StatelessWidget {
  final bool isCorrect;
  final String analysisText;
  final String? audioFilePath;
  final List<String> goodPoints;
  final List<String> improvementPoints;

  const _SpeakingExplanationContent({
    super.key,
    required this.isCorrect,
    required this.analysisText,
    this.audioFilePath,
    required this.goodPoints,
    required this.improvementPoints,
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
          // "Answer analysis" heading
          AppText(
            'Answer analysis',
            style: AppStyle.text20.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0D121C),
            ),
          ),
          16.verticalSpace,
          // Analysis text
          AppText(
            analysisText,
            maxLines: 100,
            style: AppStyle.text14.copyWith(
              color: const Color(0xFF364152),
              height: 1.5,
            ),
          ),
          16.verticalSpace,
          // Audio player (if available)
          if (audioFilePath != null) ...[
            AudioPlayerWidget(audioUrl: audioFilePath),
            16.verticalSpace,
          ],
          // Good points section
          if (goodPoints.isNotEmpty) ...[
            _buildGoodPointsSection(),
            16.verticalSpace,
          ],
          // Can be improved section
          if (improvementPoints.isNotEmpty) ...[
            _buildImprovementSection(),
          ],
        ],
      ),
    );
  }

  
  Widget _buildGoodPointsSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFEBEAFD),
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
                'Good points',
                style: AppStyle.textBold14.copyWith(
                  color: const Color(0xFF554FF0),
                  height: 1.75,
                ),
              ),
            ],
          ),
          8.verticalSpace,
          // Good points list
          ...goodPoints.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: entry.key < goodPoints.length - 1 ? 4.h : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    '${entry.key + 1}. ',
                    style: AppStyle.text14.copyWith(
                      color: const Color(0xFF364152),
                      height: 1.5,
                    ),
                  ),
                  Expanded(
                    child: AppText(
                      entry.value,
                      maxLines: 100,
                      style: AppStyle.text14.copyWith(
                        color: const Color(0xFF364152),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildImprovementSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4EE),
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
              Icon(
                Icons.auto_fix_high_rounded,
                color: const Color(0xFF41AE8C),
                size: 20.w,
              ),
              6.horizontalSpace,
              AppText(
                'Can be improved',
                style: AppStyle.textBold14.copyWith(
                  color: const Color(0xFF41AE8C),
                  height: 1.75,
                ),
              ),
            ],
          ),
          8.verticalSpace,
          // Improvement points list
          ...improvementPoints.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: entry.key < improvementPoints.length - 1 ? 4.h : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    '${entry.key + 1}. ',
                    style: AppStyle.text14.copyWith(
                      color: const Color(0xFF364152),
                      height: 1.5,
                    ),
                  ),
                  Expanded(
                    child: AppText(
                      entry.value,
                      maxLines: 100,
                      style: AppStyle.text14.copyWith(
                        color: const Color(0xFF364152),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}