part of '../../../../lesson.dart';

class SpeakingResultBottomSheet extends StatelessWidget {
  final ResultType type;
  final VoidCallback onContinue;

  const SpeakingResultBottomSheet({
    super.key,
    required this.type,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final explanationVisible = true;

    return LessonResultOverlay(
      showExplanation: explanationVisible,
      // onBackdropTap: explanationVisible ? onExplain : null,
      explanation: SpeakingExplanationContent(),
      summary: ExerciseResultSummary(
        type: type,
        onContinue: onContinue,
        onExplain: () => context.read<SpeakingCubit>().toggleExplanation(),
        continueLabel: context.text.onboardingSkipGreetingButton,
        explainLabel: context.text.exerciseExplainButton,
        closeExplainLabel: context.text.exerciseCloseExplainButton,
        title: context.text.exerciseCompleteVoiceTask,
      ),
    );
  }
}

class SpeakingExplanationContent extends StatelessWidget {
  const SpeakingExplanationContent({super.key});

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
            context.text.exerciseVoiceAnalysisTitle,
            style: AppStyle.text20.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0D121C),
            ),
          ),
          BlocSelector<SpeakingCubit, SpeakingState, String>(
            selector: (state) => state.textInput,
            builder: (context, textInput) {
              if (textInput.isEmpty) return const SizedBox.shrink();
              return AppText(
                textInput,
                maxLines: 100,
                margin: EdgeInsets.only(top: 16.h),
                style: AppStyle.text14.copyWith(
                  color: const Color(0xFF364152),
                  height: 1.5,
                ),
              );
            },
          ),
          BlocSelector<SpeakingCubit, SpeakingState, String>(
            selector: (state) => state.audioFilePath ?? '',
            builder: (context, audioFilePath) {
              if (audioFilePath.isEmpty) return const SizedBox.shrink();
              return Container(
                margin: EdgeInsets.only(top: 16.h),
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  border: Border.all(color: AppCustomColor.borderDefault, width: 2.w),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: AudioPlayerWidget(filePath: audioFilePath),
              );
            },
          ),
          BlocSelector<SpeakingCubit, SpeakingState, List<String>>(
            selector: (state) => [
              'Paraphrasing means restating',
              'what the other person has said in your own words',
            ],
            builder: (context, goodPoints) {
              if (goodPoints.isEmpty) return const SizedBox.shrink();
              return SpeakingGoodPointsSection(points: goodPoints);
            },
          ),
          BlocSelector<SpeakingCubit, SpeakingState, List<String>>(
            selector: (state) => [
              'Try to use more varied vocabulary',
              'Improve pronunciation clarity',
            ],
            builder: (context, improvementPoints) {
              if (improvementPoints.isEmpty) return const SizedBox.shrink();
              return SpeakingImprovementSection(points: improvementPoints);
            },
          ),
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
      margin: EdgeInsets.only(top: 16.h),
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
                context.text.exerciseGoodPointsTitle,
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
      margin: EdgeInsets.only(top: 16.h),
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
                context.text.exerciseBadPointsTitle,
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
