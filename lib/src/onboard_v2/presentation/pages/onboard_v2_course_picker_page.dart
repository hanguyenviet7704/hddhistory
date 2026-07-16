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
    _courseController = PageController(viewportFraction: _p8CourseViewportFraction);
    _requestTrackingPermission();
  }

  void _requestTrackingPermission() {
    AppService.instance.appEventService.requestTrackingPermission();
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
        backgroundColor: AppCustomColor.backgroundWhite,
        cta: _buildCta(state, onboardingL10n),
        child: Column(
          children: [
            12.verticalSpace,
            AppText(
              onboardingL10n.onboardingV2P8Eyebrow,
              textAlign: TextAlign.center,
              style: AppStyle.text14.copyWith(color: AppCustomColor.textPrimary.op(0.5), height: 1.75),
            ),
            AppText(
              onboardingL10n.onboardingV2P8Title,
              textAlign: TextAlign.center,
              style: AppStyle.text20.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w700, height: 1.5),
            ),
            24.verticalSpace,
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

  Widget _buildCta(OnboardV2State state, Translations$onboarding$en onboardingL10n) {
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

    final intent = await const CourseHandoffHelper().prepareRecommendedCourse(
      course: resolvedCourse,
      // Await the prewarmed home load (already in-flight since P8 opened)
      // instead of a fresh cold fetch — no duplicate round-trips, and the wait
      // is near-zero when the prewarm has already completed.
      initializeHomeData: cubit.prewarmHomeData,
    );
    if (!mounted) return;
    _dispatchRoute(intent, selectedCourseId: resolvedCourse.id);
  }

  Future<void> _goCourseCatalog() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    final intent = await const CourseHandoffHelper().prepareCourseCatalog(
      initializeHomeData: context.read<OnboardV2Cubit>().prewarmHomeData,
    );
    if (!mounted) return;
    _dispatchRoute(intent);
  }

  void _dispatchRoute(CourseHandoffRouteIntent intent, {String? selectedCourseId}) {
    try {
      var destination = 'course';
      final onboardCubit = context.read<OnboardV2Cubit>();
      final userCubit = context.read<UserCubit>();
      onboardCubit.markUserOnboardedInBackground();
      userCubit.setOnboardingPathOrder(onboardCubit.state.selectedPaths);
      switch (intent) {
        case CourseHandoffRouteIntent.courseRoadmap:
          CourseRoadmapRoute().go(context);
          // Every OTHER roadmap entry point pairs .go() with this (see
          // all_course_tab.dart) — .go() to the roadmap branch root doesn't
          // re-fire the route observer, so without it PageCubit.currentRouteName
          // stays on whatever it was before onboarding. That silently breaks
          // two things gated on it: the re-anchor prompt (§9.1) never fires for
          // a brand-new user's very first course, and the floating bottom nav
          // (gated on isPrimaryRoute) can stay hidden with no way back out.
          context.read<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
          destination = 'course_roadmap';
          break;
        case CourseHandoffRouteIntent.course:
          CourseRoute(selectedTabIndex: 0).go(context);
          break;
      }
      userCubit.setIsUserPassOnboarding(false);
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

const _p8CourseViewportFraction = 0.82;
const _p8SideCourseCardScale = 220 / 260;

class _CourseCarousel extends StatelessWidget {
  const _CourseCarousel({required this.controller, required this.state});

  final PageController controller;
  final OnboardV2State state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardV2Cubit>();
    final course = state.currentCourse;
    final isFirstCourse = state.currentCourseIndex == 0;
    final hasMultipleCourses = state.recommendedCourses.length > 1;
    return Column(
      children: [
        if (isFirstCourse) const _BestMatchedLabel() else 21.verticalSpace,
        12.verticalSpace,
        SizedBox(
          height: 260.w,
          child: OverflowBox(
            minWidth: MediaQuery.sizeOf(context).width,
            maxWidth: MediaQuery.sizeOf(context).width,
            alignment: Alignment.center,
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width,
              height: 260.w,
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
                      final scale = 1.0 - (distance * (1.0 - _p8SideCourseCardScale));
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: OnboardV2CoursePickerCard(course: course),
                  );
                },
              ),
            ),
          ),
        ),
        if (hasMultipleCourses) ...[
          12.verticalSpace,
          Row(
            key: const Key('onboard_v2_course_indicator_row'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(state.recommendedCourses.length, (index) {
              final active = index == state.currentCourseIndex;
              return AnimatedContainer(
                key: ValueKey('onboard_v2_course_indicator_$index'),
                duration: const Duration(milliseconds: 180),
                width: 8.w,
                height: 8.w,
                margin: EdgeInsets.symmetric(horizontal: 6.w),
                decoration: BoxDecoration(
                  color: active ? AppCustomColor.brandPrimary : AppCustomColor.borderSecondary,
                  borderRadius: BorderRadius.circular(100.r),
                ),
              );
            }),
          ),
        ],
        24.verticalSpace,
        if (course != null) _CurrentCourseText(course: course),
      ],
    );
  }
}

class _BestMatchedLabel extends StatelessWidget {
  const _BestMatchedLabel();

  @override
  Widget build(BuildContext context) {
    final onboardingL10n = context.l10n.onboarding;
    return Row(
      key: const Key('onboard_v2_course_best_matched_label'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _labelStar(),
        8.horizontalSpace,
        AppText(
          onboardingL10n.onboardingV2P8Label.toUpperCase(),
          textAlign: TextAlign.center,
          style: AppStyle.text12.copyWith(color: AppCustomColor.brandPrimary, fontWeight: FontWeight.w700, height: 1.75),
        ),
        8.horizontalSpace,
        _labelStar(),
      ],
    );
  }

  Widget _labelStar() {
    return Icon(Icons.star_rounded, size: 8.w, color: AppCustomColor.brandPrimary.op(0.35));
  }
}

class _CurrentCourseText extends StatelessWidget {
  const _CurrentCourseText({required this.course});

  final CourseEntity course;

  @override
  Widget build(BuildContext context) {
    final onboardingL10n = context.l10n.onboarding;
    final title = course.title.text.trim().isNotEmpty ? course.title.text.trim() : onboardingL10n.onboardingV2P8CourseTitleFallback;
    final description = course.description.text.trim();
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          AppText(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppStyle.text24.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w700, height: 1.5),
          ),
          if (description.isNotEmpty) ...[
            4.verticalSpace,
            AppText(
              description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary, height: 1.75),
            ),
          ],
        ],
      ),
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
