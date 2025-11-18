// ignore_for_file: public_member_api_docs, sort_constructors_first
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
    return BlocBuilder<SpeakingCubit, SpeakingState>(
      builder: (context, state) => LessonResultOverlay(
        showExplanation: state.showExplanation,
        // onBackdropTap: explanationVisible ? onExplain : null,
        explanation: SpeakingExplanationContent(
          textInput: state.textInput,
          audioFilePath: state.audioFilePath ?? '',
          goodPoints: state.goodPoints,
          improvementPoints: state.improvementPoints,
        ),
        summary: ExerciseResultSummary(
          type: type,
          onContinue: onContinue,
          showExplanation: state.showExplanation,
          onExplain: () => context.read<SpeakingCubit>().toggleExplanation(),
          continueLabel: context.text.onboardingSkipGreetingButton,
          explainLabel: context.text.exerciseExplainButton,
          closeExplainLabel: context.text.exerciseCloseExplainButton,
          title: context.text.exerciseCompleteVoiceTask,
        ),
      ),
    );
  }
}

class SpeakingExplanationContent extends StatelessWidget {
  final String textInput;
  final String audioFilePath;
  final String goodPoints;
  final String improvementPoints;
  const SpeakingExplanationContent({
    super.key,
    this.textInput = '',
    this.audioFilePath = '',
    this.goodPoints = '',
    this.improvementPoints = '',
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        child: Container(
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
              if (textInput.isNotEmpty)
                AppText(
                  textInput,
                  maxLines: 100,
                  margin: EdgeInsets.only(top: 16.h),
                  style: AppStyle.text14.copyWith(
                    color: const Color(0xFF364152),
                    height: 1.5,
                  ),
                ),
              if (audioFilePath.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(top: 16.h),
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppCustomColor.borderDefault, width: 2.w),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: AudioPlayerWidget(filePath: audioFilePath),
                ),
              SpeakingGoodPointsSection(points: goodPoints),
              SpeakingImprovementSection(points: improvementPoints),
            ],
          ),
        ),
      ),
    );
  }
}

class SpeakingGoodPointsSection extends StatelessWidget {
  final String points;

  const SpeakingGoodPointsSection({
    super.key,
    this.points = '',
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
          AppText(
            points,
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

class SpeakingImprovementSection extends StatelessWidget {
  final String points;

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
          AppText(
            points,
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
