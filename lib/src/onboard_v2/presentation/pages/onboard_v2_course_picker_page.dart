part of '../../onboard_v2.dart';

class OnboardV2CoursePickerPage extends StatefulWidget {
  const OnboardV2CoursePickerPage({super.key});

  @override
  State<OnboardV2CoursePickerPage> createState() => _OnboardV2CoursePickerPageState();
}

class _OnboardV2CoursePickerPageState extends State<OnboardV2CoursePickerPage> {
  late final PageController _courseController;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _courseController = PageController(viewportFraction: 0.72);
  }

  @override
  void dispose() {
    _courseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardV2Cubit>().state;
    final onboardingL10n = context.l10n.onboarding;
    return PopScope(
      canPop: false,
      child: OnboardV2ScreenShell(
        backgroundColor: AppCustomColor.backgroundBrandSoft,
        cta: _buildCta(state, onboardingL10n),
        child: Column(
          children: [
            40.verticalSpace,
            AppText(
              onboardingL10n.onboardingV2P8Eyebrow,
              textAlign: TextAlign.center,
              style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary, fontWeight: FontWeight.w700),
            ),
            8.verticalSpace,
            AppText(
              onboardingL10n.onboardingV2P8Title,
              textAlign: TextAlign.center,
              style: AppStyle.text28.copyWith(color: AppCustomColor.textBrand, fontWeight: FontWeight.w800, height: 1.3),
            ),
            32.verticalSpace,
            if (state.courseStatus == OnboardV2CourseStatus.loading)
              SizedBox(
                height: 340.w,
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (state.hasRecommendedCourses)
              _CourseCarousel(controller: _courseController, state: state)
            else
              _FallbackContent(message: state.courseErrorMessage),
          ],
        ),
      ),
    );
  }

  Widget _buildCta(OnboardV2State state, TranslationsOnboardingEn onboardingL10n) {
    final course = state.currentCourse;
    if (state.courseStatus == OnboardV2CourseStatus.loading) {
      return OnboardV2BottomCta(label: onboardingL10n.onboardingV2P8SelectCta, isLoading: true, onPressed: null);
    }

    if (course != null && course.id.isNotEmpty) {
      return OnboardV2BottomCta(
        label: onboardingL10n.onboardingV2P8SelectCta,
        isLoading: _isNavigating,
        onPressed: () => unawaited(_goSelectedCourse(course)),
      );
    }

    return OnboardV2BottomCta(
      label: onboardingL10n.onboardingV2RetryCta,
      isLoading: _isNavigating,
      onPressed: () => unawaited(context.read<OnboardV2Cubit>().retryCoursesForP8()),
      secondaryLabel: onboardingL10n.onboardingV2P8CatalogCta,
      onSecondaryPressed: () => unawaited(_goCourseCatalog()),
    );
  }

  Future<void> _goSelectedCourse(CourseEntity course) async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
    final cubit = context.read<OnboardV2Cubit>();
    OnboardV2Tracking.track(
      TrackingKey.onboardV2CourseSelectClick,
      parameters: OnboardV2Tracking.courseSelectParams(
        course: course,
        currentCourseIndex: cubit.state.currentCourseIndex,
      ),
    );

    final resolvedCourse = await cubit.resolveCourseForHandoff(course);
    if (!mounted) return;
    if (resolvedCourse == null) {
      setState(() => _isNavigating = false);
      return;
    }

    final intent = await const CourseHandoffHelper().prepareRecommendedCourse(course: resolvedCourse);
    if (!mounted) return;
    _dispatchRoute(intent, selectedCourseId: resolvedCourse.id);
  }

  Future<void> _goCourseCatalog() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    final intent = await const CourseHandoffHelper().prepareCourseCatalog();
    if (!mounted) return;
    _dispatchRoute(intent);
  }

  void _dispatchRoute(CourseHandoffRouteIntent intent, {String? selectedCourseId}) {
    try {
      var destination = 'course';
      context.read<OnboardV2Cubit>().markUserOnboardedInBackground();
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
      final parameters = <String, dynamic>{
        'destination': destination,
      };
      if (selectedCourseId != null) {
        parameters['selected_course_id'] = selectedCourseId;
      }
      OnboardV2Tracking.track(
        TrackingKey.onboardV2Complete,
        parameters: parameters,
      );
    } catch (error) {
      LogDev.warning('[OnboardV2CoursePickerPage] route dispatch failed: $error');
      if (mounted) setState(() => _isNavigating = false);
    }
  }
}

class _CourseCarousel extends StatelessWidget {
  const _CourseCarousel({required this.controller, required this.state});

  final PageController controller;
  final OnboardV2State state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardV2Cubit>();
    return Column(
      children: [
        SizedBox(
          height: 380.w,
          child: PageView.builder(
            key: const Key('onboard_v2_course_picker_page_view'),
            controller: controller,
            itemCount: state.recommendedCourses.length,
            onPageChanged: cubit.setCurrentCourseIndex,
            itemBuilder: (context, index) {
              final course = state.recommendedCourses[index];
              return AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  final page = controller.hasClients ? (controller.page ?? controller.initialPage.toDouble()) : state.currentCourseIndex.toDouble();
                  final distance = (page - index).abs().clamp(0.0, 1.0);
                  final scale = 1.0 - (distance * 0.12);
                  return Transform.scale(scale: scale, child: child);
                },
                child: OnboardV2CoursePickerCard(course: course),
              );
            },
          ),
        ),
        16.verticalSpace,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(state.recommendedCourses.length, (index) {
            final active = index == state.currentCourseIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: active ? 18.w : 8.w,
              height: 8.w,
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              decoration: BoxDecoration(
                color: active ? AppCustomColor.brandPrimary : AppCustomColor.borderSecondary,
                borderRadius: BorderRadius.circular(100.r),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _FallbackContent extends StatelessWidget {
  const _FallbackContent({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final onboardingL10n = context.l10n.onboarding;
    return SizedBox(
      height: 340.w,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_rounded, size: 80.w, color: AppCustomColor.brandPrimary),
          24.verticalSpace,
          AppText(
            onboardingL10n.onboardingV2P8FallbackTitle,
            textAlign: TextAlign.center,
            style: AppStyle.text24.copyWith(color: AppCustomColor.textBrand, fontWeight: FontWeight.w800),
          ),
          12.verticalSpace,
          AppText(
            onboardingL10n.onboardingV2P8FallbackCopy,
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
            style: AppStyle.text16.copyWith(color: AppCustomColor.textSecondary),
          ),
        ],
      ),
    );
  }
}
