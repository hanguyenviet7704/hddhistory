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
          continueLabel: context.text.onboarding.onboardingSkipGreetingButton,
          explainLabel: context.text.exercise.exerciseExplainButton,
          closeExplainLabel: context.text.exercise.exerciseCloseExplainButton,
          title: context.text.exercise.exerciseCompleteVoiceTask,
        ),
      ),
    );
  }
}

class SpeakingExplanationContent extends StatelessWidget {
  final String textInput;
  final String audioFilePath;
  final List<String> goodPoints;
  final List<String> improvementPoints;
  const SpeakingExplanationContent({
    super.key,
    this.textInput = '',
    this.audioFilePath = '',
    this.goodPoints = const [],
    this.improvementPoints = const [],
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
                context.text.exercise.exerciseVoiceAnalysisTitle,
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
  final List<String> points;

  const SpeakingGoodPointsSection({
    super.key,
    this.points = const [],
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
                context.text.exercise.exerciseGoodPointsTitle,
                style: AppStyle.textBold14.copyWith(
                  color: const Color(0xFF554FF0),
                  height: 1.75,
                ),
              ),
            ],
          ),
          8.verticalSpace,
          BlocSelector<SpeakingCubit, SpeakingState, List<String>>(
            selector: (state) => state.goodPoints,
            builder: (context, goodPoints) {
              return AnimateSwitch(
                child: goodPoints.isEmpty
                    ? const _SpeakingPointsSkeleton(
                        key: ValueKey('skeleton-goodPoints'),
                        baseColor: Color(0xFFC7C5FA),
                        highlightColor: Color(0xFFEBEAFD),
                      )
                    : AnimatedPointsList(
                        key: ValueKey('good-points'),
                        points: goodPoints,
                        textStyle: AppStyle.text14.copyWith(
                          color: const Color(0xFF364152),
                          height: 1.5,
                        ),
                        indexColor: const Color(0xFF554FF0),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class SpeakingImprovementSection extends StatelessWidget {
  final List<String> points;

  const SpeakingImprovementSection({
    super.key,
    this.points = const [],
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
                context.text.exercise.exerciseBadPointsTitle,
                style: AppStyle.textBold14.copyWith(
                  color: const Color(0xFF41AE8C),
                  height: 1.75,
                ),
              ),
            ],
          ),
          8.verticalSpace,
          BlocSelector<SpeakingCubit, SpeakingState, List<String>>(
            selector: (state) => state.improvementPoints,
            builder: (context, improvementPoints) {
              return AnimateSwitch(
                child: improvementPoints.isEmpty
                    ? const _SpeakingPointsSkeleton(
                        key: ValueKey('skeleton-improvementPoints'),
                        baseColor: Color(0xFFB3DDCC),
                        highlightColor: Color(0xFFE6F4EE),
                      )
                    : AnimatedPointsList(
                        key: ValueKey('improvement-points'),
                        points: improvementPoints,
                        textStyle: AppStyle.text14.copyWith(
                          color: const Color(0xFF364152),
                          height: 1.5,
                        ),
                        indexColor: const Color(0xFF41AE8C),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class AnimatedPointsList extends StatelessWidget {
  final List<String> points;
  final TextStyle textStyle;
  final Color indexColor;

  const AnimatedPointsList({
    super.key,
    required this.points,
    required this.textStyle,
    required this.indexColor,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: points.asMap().entries.map((entry) {
          return TweenAnimationBuilder<double>(
            key: ValueKey('point-${entry.key}'),
            duration: const Duration(milliseconds: 300),
            tween: Tween(begin: 0, end: 1),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 8),
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.only(bottom: entry.key < points.length - 1 ? 4.h : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    '${entry.key + 1}. ',
                    style: textStyle.copyWith(
                      fontWeight: FontWeight.w600,
                      color: indexColor,
                    ),
                  ),
                  Expanded(
                    child: AppText(
                      entry.value,
                      maxLines: 100,
                      style: textStyle,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SpeakingPointsSkeleton extends StatelessWidget {
  final Color baseColor;
  final Color highlightColor;

  const _SpeakingPointsSkeleton({
    super.key,
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor.withValues(alpha: 0.6),
      highlightColor: highlightColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 9.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(30.r),
            ),
          ),
          8.verticalSpace,
          Container(
            height: 9.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(30.r),
            ),
          ),
          8.verticalSpace,
          Container(
            height: 9.h,
            width: 137.w,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(30.r),
            ),
          ),
        ],
      ),
    );
  }
}
