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

  @override
  Widget build(BuildContext context) {
    final hasExplanation = (analysisText ?? '').isNotEmpty;
    final explanationVisible = hasExplanation && showExplanation;
    final titleOverride = type == ResultType.correct && explanationVisible ? 'Completed!' : null;

    return LessonResultOverlay(
      showExplanation: explanationVisible,
      // onBackdropTap: explanationVisible ? onExplain : null,
      explanation: hasExplanation
          ? SpeakingExplanationContent(
              analysisText: analysisText!,
              audioFilePath: audioFilePath,
              goodPoints: goodPoints ?? const [],
              improvementPoints: improvementPoints ?? const [],
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
        title: titleOverride,
      ),
    );
  }
}

class SpeakingExplanationContent extends StatelessWidget {
  final String analysisText;
  final String? audioFilePath;
  final List<String> goodPoints;
  final List<String> improvementPoints;

  const SpeakingExplanationContent({
    super.key,
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
          AppText(
            'Answer analysis',
            style: AppStyle.text20.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0D121C),
            ),
          ),
          16.verticalSpace,
          AppText(
            analysisText,
            maxLines: 100,
            style: AppStyle.text14.copyWith(
              color: const Color(0xFF364152),
              height: 1.5,
            ),
          ),
          if (audioFilePath != null) ...[
            16.verticalSpace,
            AudioPlayerWidget(audioUrl: audioFilePath),
          ],
          if (goodPoints.isNotEmpty) ...[
            16.verticalSpace,
            SpeakingGoodPointsSection(points: goodPoints),
          ],
          if (improvementPoints.isNotEmpty) ...[
            16.verticalSpace,
            SpeakingImprovementSection(points: improvementPoints),
          ],
        ],
      ),
    );
  }
}

class SpeakingGoodPointsSection extends StatelessWidget {
  final List<String> points;

  const SpeakingGoodPointsSection({
    super.key,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
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
          ...points.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: entry.key < points.length - 1 ? 4.h : 0),
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

class SpeakingImprovementSection extends StatelessWidget {
  final List<String> points;

  const SpeakingImprovementSection({
    super.key,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
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
          ...points.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: entry.key < points.length - 1 ? 4.h : 0),
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
