part of '../../onboard_v2.dart';

class OnboardV2RecommendationPage extends StatefulWidget {
  const OnboardV2RecommendationPage({super.key});

  @override
  State<OnboardV2RecommendationPage> createState() => _OnboardV2RecommendationPageState();
}

class _OnboardV2RecommendationPageState extends State<OnboardV2RecommendationPage> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardV2Cubit>().state;
    final course = state.recommendedCourse;
    final onboardingL10n = context.l10n.onboarding;
    return PopScope(
      canPop: false,
      child: OnboardV2ScreenShell(
        backgroundColor: AppCustomColor.backgroundBrandSoft,
        cta: course == null || course.id.isEmpty
            ? _secondaryOnlyCta()
            : Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: OnboardV2BottomCta(
                  label: onboardingL10n.onboardingV2P7PrimaryCta,
                  isLoading: _isNavigating,
                  onPressed: () => unawaited(_goRecommendedCourse(course)),
                ),
              ),
        child: Column(
          children: [
            SizedBox(height: 96.w),
            if (state.recommendationStatus == OnboardV2RecommendationStatus.loading)
              const SizedBox.shrink()
            else if (course != null && course.id.isNotEmpty)
              OnboardV2CourseRecommendationCard(course: course)
            else ...[
              120.verticalSpace,
              Icon(Icons.explore_rounded, size: 82.w, color: AppCustomColor.brandPrimary),
              24.verticalSpace,
              AppText(
                onboardingL10n.onboardingV2P7FallbackTitle,
                textAlign: TextAlign.center,
                style: AppStyle.text28.copyWith(color: AppCustomColor.textBrand, fontWeight: FontWeight.w800),
              ),
              12.verticalSpace,
              AppText(
                onboardingL10n.onboardingV2P7FallbackCopy,
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
                style: AppStyle.text16.copyWith(color: AppCustomColor.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _secondaryOnlyCta() {
    return TextButton(
      key: const Key('onboard_v2_secondary_cta'),
      onPressed: _isNavigating ? null : () => unawaited(_goCourse()),
      child: AppText(
        context.l10n.onboarding.onboardingV2P7SecondaryCta,
        style: AppStyle.text14.copyWith(
          color: AppCustomColor.brandPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Future<void> _goRecommendedCourse(CourseEntity course) async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
    OnboardV2Tracking.track(
      TrackingKey.onboardV2JumpInClick,
      parameters: {'recommended_course_id': course.id},
    );

    final intent = await const CourseHandoffHelper().prepareRecommendedCourse(course: course);
    if (!mounted) return;

    _dispatchRoute(intent);
  }

  Future<void> _goCourse() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
    OnboardV2Tracking.track(TrackingKey.onboardV2ExploreMyOwnClick);

    final intent = await const CourseHandoffHelper().prepareCourseCatalog();
    if (!mounted) return;

    _dispatchRoute(intent);
  }

  void _dispatchRoute(CourseHandoffRouteIntent intent) {
    try {
      var destination = 'course';
      switch (intent) {
        case CourseHandoffRouteIntent.courseRoadmap:
          CourseRoadmapRoute().go(context);
          destination = 'course_roadmap';
          break;
        case CourseHandoffRouteIntent.course:
          CourseRoute(selectedTabIndex: 0).go(context);
          break;
      }
      context.read<UserCubit>().setIsUserPassOnboarding(false);
      OnboardV2Tracking.track(
        TrackingKey.onboardV2Complete,
        parameters: {'destination': destination},
      );
    } catch (error) {
      LogDev.warning('[OnboardV2RecommendationPage] route dispatch failed: $error');
      if (mounted) setState(() => _isNavigating = false);
    }
  }
}
