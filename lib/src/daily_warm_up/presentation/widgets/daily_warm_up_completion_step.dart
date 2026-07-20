part of '../../daily_warm_up.dart';

class DailyWarmUpCompletionStep extends StatelessWidget {
  const DailyWarmUpCompletionStep({
    super.key,
    required this.state,
    required this.onStartLesson,
    required this.onExploreMore,
  });

  final DailyWarmUpState state;
  final VoidCallback onStartLesson;
  final VoidCallback onExploreMore;

  @override
  Widget build(BuildContext context) {
    final entity = state.entity;
    final subtitle = entity?.isCourseCompleted == true ? context.l10n.dailyWarmUp.keepLearningWithNewCourses : context.l10n.dailyWarmUp.readyToContinueProgress;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F1FE),
      body: SafeArea(
        child: Stack(
          children: [
            const _DailyWarmUpCongratulationsBackground(),
            ListView(
              padding: EdgeInsets.fromLTRB(20.w, 84.h, 20.w, 24.h),
              children: [
                ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    colors: [Color(0xFF4B44CA), Color(0xFFA052FF), Color(0xFFEF81D4), Color(0xFFFF8F8F), Color(0xFFFFCE66)],
                  ).createShader(rect),
                  child: AppText(
                    context.l10n.dailyWarmUp.completeChallenge,
                    textAlign: TextAlign.center,
                    style: AppStyle.text32.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
                12.verticalSpace,
                AppText(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  style: AppStyle.text16.copyWith(color: const Color(0xFF364152), fontWeight: FontWeight.w500),
                ),
                40.verticalSpace,
                if (state.suggestedCourse != null)
                  Center(child: DailyWarmUpCourseCard(course: state.suggestedCourse!))
                else
                  SizedBox(
                    height: 180.h,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                32.verticalSpace,
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DailyWarmUpBottomCta(
            label: context.l10n.dailyWarmUp.startTodaysLesson,
            enabled: state.suggestedCourse != null && !state.isLoadingCourse,
            isLoading: state.isRoutingToRoadmap,
            onPressed: onStartLesson,
          ),
          TextButton(
            onPressed: () {
              AppHaptic.select();
              onExploreMore();
            },
            child: AppText(
              context.l10n.dailyWarmUp.exploreMore,
              style: AppStyle.text16.copyWith(color: const Color(0xFF362F82), fontWeight: FontWeight.w600),
            ),
          ),
          32.verticalSpace,
        ],
      ),
    );
  }
}

class _DailyWarmUpCongratulationsBackground extends StatelessWidget {
  const _DailyWarmUpCongratulationsBackground();

  @override
  Widget build(BuildContext context) {
    if ((MediaQuery.maybeDisableAnimationsOf(context) ?? false) || MediaQuery.accessibleNavigationOf(context)) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: Lottie.asset(
          AppAsset.lottie.congratulations,
          fit: BoxFit.cover,
          repeat: true,
        ),
      ),
    );
  }
}
