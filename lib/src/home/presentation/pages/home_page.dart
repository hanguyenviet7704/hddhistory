part of '../../home.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with _HomeInAppSurveyMixin, _HomeDailyWarmUpMixin {
  void _trackHomeScrView() {
    AppService.instance.appTrackingService.trackHomeScrView();
  }

  Future<void> _prefetchLearningStreak() async {
    final userId = context.read<UserCubit>().state.user.id;
    await context.read<LearningStreakCubit>().loadUserLearningStreak(
      triggerSource: LearningStreakTriggerSource.homeChip,
      requestedUserId: userId,
      timeout: const Duration(seconds: 2),
      emitLoading: false,
      allowSafeDefaultOnFailure: true,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _trackHomeScrView();
      // Recover from a failed/skipped first load (e.g. transient failure right
      // after a fresh install) instead of showing a blank Home until the user
      // pull-to-refreshes or restarts the app. No-op when data is present.
      unawaited(context.read<HomeCubit>().ensureHomeDataLoaded());
      // Same recovery for the "Continue learning" my-courses list — it can
      // fail independently of skillsets since both load inside the same
      // Future.wait.
      unawaited(context.read<ProgressCubit>().ensureMyCoursesLoaded());
      // And for the recommended-courses strip, hidden when empty.
      unawaited(context.read<HomeCubit>().ensureSuggestedCoursesLoaded());
      // Habit data so the check-in reminder card (§9.4) knows today's count.
      unawaited(AppDI.injector.get<HabitCubit>().ensureLoaded());
      await _prefetchLearningStreak();
      final didOpenPaywall = await _tryOpenPaywallAutoOpen();
      if (didOpenPaywall) return;
      final didOpenWarmUp = await _tryOpenDailyWarmUp();
      if (!didOpenWarmUp) {
        await _loadInAppSurveyConfig();
        if (mounted) _handleSurveyStateChanged(context.read<InAppSurveyCubit>().state);
      }
      await _maybeOpenWeeklyRecap();
    });
  }

  /// Weekly recap auto-opens on the recap day (PRD §9.9), after the paywall/
  /// warm-up/survey gates so it never stacks on top of them.
  ///
  /// Whether it's the recap day is decided by the SERVER (summary.isRecapDay),
  /// not the device clock — so we must load the summary before checking. Skip
  /// the fetch entirely for users with no active habits (they can never see a
  /// recap), so this stays a no-op cost on most Home opens.
  Future<void> _maybeOpenWeeklyRecap() async {
    final habitCubit = AppDI.injector.get<HabitCubit>();
    // Make sure habits are loaded before reading activeHabits (cold start:
    // this runs after the paywall/warm-up gates, but the habit fetch kicked
    // off in initState may not have landed yet).
    await habitCubit.ensureLoaded();
    if (!mounted || habitCubit.state.activeHabits.isEmpty) return;
    await habitCubit.loadSummary();
    if (!mounted) return;
    if (!habitCubit.state.shouldShowWeeklyRecap) return;
    habitCubit.markWeeklyRecapShown();
    await const HabitSummaryRoute().push(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PageCubit, PageState>(
      listenWhen: (previous, current) => previous.currentIndex != current.currentIndex,
      listener: (context, state) {
        if (state.currentIndex == 0) {
          _trackHomeScrView();
          // Returning to the Home tab with an empty catalog (initial retry
          // also failed) → try again.
          unawaited(context.read<HomeCubit>().ensureHomeDataLoaded());
          // Same recovery for the "Continue learning" my-courses list.
          unawaited(context.read<ProgressCubit>().ensureMyCoursesLoaded());
          // And for the recommended-courses strip, hidden when empty.
          unawaited(context.read<HomeCubit>().ensureSuggestedCoursesLoaded());
        }
      },
      child: BlocListener<InAppSurveyCubit, InAppSurveyState>(
        listenWhen: (previous, current) => previous.isEntryVisible != current.isEntryVisible,
        listener: (context, state) => _handleSurveyStateChanged(state),
        child: Scaffold(
          key: const Key('home-page'),
          // Behind the status bar — must match the header gradient's TOP colour
          // (#B0ACF5) so there's no seam ("2 màu") between the status-bar strip
          // and the header. (Was #BEBCF6, the old top colour.)
          backgroundColor: const Color(0xFFB0ACF5),
          body: SafeBody(
            child: Stack(
              children: [
                // The whole page scrolls as one unit — the purple header
                // scrolls away together with the content (no pinned header).
                RefreshIndicator(
                  onRefresh: () async {
                    context.read<HomeCubit>().initializeData(isInit: true, force: true);
                    await _prefetchLearningStreak();
                    final didOpenPaywall = await _tryOpenPaywallAutoOpen();
                    if (didOpenPaywall) return;
                    final didOpenWarmUp = await _tryOpenDailyWarmUp();
                    if (!didOpenWarmUp) await _loadInAppSurveyConfig();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    // Backdrop = the header gradient's BOTTOM colour (#8579F3) so
                    // the white sheet's rounded top corners reveal that same deep
                    // purple, letting the sheet "rise out of" the header. (Was
                    // #DFDDF8 — the old faded bottom — which showed a pale/white
                    // haze at the corners now that the header ends dark.)
                    child: ColoredBox(
                      color: const Color(0xFF8579F3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Purple header — scrolls with the page.
                          const HomeHeaderWidget(),
                          Container(
                            width: double.infinity,
                            // Rounded top corners — the white sheet rises out
                            // of the lavender header (Figma home screen).
                            decoration: BoxDecoration(
                              color: AppCustomColor.backgroundWhite,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20.r),
                                topRight: Radius.circular(20.r),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                24.verticalSpace,

                                // ── Continue learning ────────────────────
                                BlocBuilder<ProgressCubit, ProgressState>(
                                  // Only myCoursesPageData drives this section — ProgressCubit
                                  // also emits on keypoint/exercise/lesson progress updates
                                  // (frequent mid-lesson), which would otherwise rebuild this
                                  // Home section even while Home is just an offstage kept-alive
                                  // branch. Mirrors course_roadmap_content.dart's buildWhen for
                                  // the same cubit.
                                  buildWhen: (previous, current) => previous.myCoursesPageData != current.myCoursesPageData,
                                  builder: (context, state) {
                                    // Only surface courses with something left to
                                    // continue — a 100%-complete course drops out
                                    // of the suggestion list entirely.
                                    final inProgress = state.myCourses.where((c) => c.completionPercentage < 100).toList();
                                    if (inProgress.isEmpty) return const SizedBox.shrink();
                                    return _ContinueLearningSection(courses: inProgress);
                                  },
                                ),

                                // ── Got ideas? banner ────────────────────
                                20.verticalSpace,
                                GotIdeasBanner(
                                  // "Có góp ý?" is the in-app survey entry — it
                                  // opens the survey popup overlay (same as the
                                  // floating pill), not a full page.
                                  onTap: _openInAppSurveyDialog,
                                ),
                                20.verticalSpace,

                                // ── Recommended courses ──────────────────
                                _RecommendedSection(
                                  onSeeAll: () {
                                    context.read<CourseCubit>()
                                      ..setAllCourseSource('home_recommend_view')
                                      ..resetExploreToAll();
                                    // Switch to the Explore shell branch (index 3).
                                    // push() stays on the Home branch; go() switches
                                    // branches and setCurrentIndex lights the right tab.
                                    context.read<PageCubit>().setCurrentIndex(3);
                                    CourseRoute().go(context);
                                  },
                                ),

                                // Bottom padding — must clear the floating nav
                                // bar, and ALSO the habit reminder card when
                                // it's showing (it floats above the nav — see
                                // this build method's Positioned(child:
                                // HomeHabitReminderCard())), otherwise the
                                // last "Gợi ý cho bạn" course titles stay
                                // clipped under those overlays. Only reserve
                                // the card's clearance while it's actually
                                // rendered, or every visit with nothing
                                // pending carries a dead gap for nothing.
                                BlocBuilder<HabitCubit, HabitState>(
                                  bloc: AppDI.injector.get<HabitCubit>(),
                                  buildWhen: (previous, current) => previous.showHomeReminder != current.showHomeReminder,
                                  builder: (context, state) {
                                    // The card's decorative illustration
                                    // (80.h, HomeHabitReminderCard) bleeds
                                    // above the card's own top edge and is the
                                    // tallest thing to clear, not the text —
                                    // Positioned gap (8.h) + illustration
                                    // height (80.h) + a small safety margin.
                                    final extra = state.showHomeReminder ? 8.h + 80.h + 16.h : 16.h;
                                    return SizedBox(height: floatingNavBarHeight(context) + extra);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // The in-app survey entry is the inline "Có góp ý?" banner
                // (GotIdeasBanner) above; the old floating pill was removed to
                // avoid showing two identical survey entries at once.

                // Habit check-in reminder — floats above the bottom nav,
                // overlaying "Continue learning" (PRD §9.4). Renders nothing
                // when there's nothing to check in today / already dismissed.
                // Clear the nav bar's ACTUAL height (varies with the device's
                // safe-area inset — 3-button nav reserves far more than
                // gesture nav) instead of a flat guess, or it clips on devices
                // with a taller inset.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: floatingNavBarHeight(context) + 8.h,
                  child: const HomeHabitReminderCard(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _tryOpenPaywallAutoOpen() async {
    if (!mounted) return false;
    final userState = context.read<UserCubit>().state;
    final user = userState.user;
    final profileCubit = context.read<ProfileCubit>();
    final didPrepare = await context.read<IapCubit>().prepareAutoOpenPaywall(
      userId: user.id,
      accessToken: userState.accessToken,
      hasCompletedOnboarding: !userState.isUserPassOnboarding,
      isPremium: profileCubit.state.user.isPremium,
      refreshPremiumStatus: () async {
        if (profileCubit.state.user.id.isEmpty && user.id.isNotEmpty) {
          profileCubit.setUser(user);
        }
        await profileCubit.loadUserIapSubscriptions();
        if (profileCubit.state.status == ProfileStatus.failure) return null;
        return profileCubit.state.user.isPremium;
      },
    );
    if (!mounted || !didPrepare) return false;
    await const PaywallRoute().push(context);
    return true;
  }
}

/// "Continue learning" section: heading + swipeable [PageView] of large portrait
/// course cards + animated page-dot indicator.
class _ContinueLearningSection extends StatefulWidget {
  final List<CourseEntity> courses;

  const _ContinueLearningSection({required this.courses});

  @override
  State<_ContinueLearningSection> createState() => _ContinueLearningSectionState();
}

class _ContinueLearningSectionState extends State<_ContinueLearningSection> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      // Full-width card — one card fills the viewport
      viewportFraction: 1.0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section heading
        AppText(
          context.l10n.home.continueLearning,
          enableFitScaleDown: true,
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          style: AppStyle.textBold20.copyWith(color: AppCustomColor.textPrimary),
        ),
        12.verticalSpace,

        // Card PageView — fixed height matching the portrait card
        SizedBox(
          height: 380.h,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemCount: widget.courses.length,
            itemBuilder: (ctx, i) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: HomeLargePortraitCourseCard(
                    course: widget.courses[i].withSkillset,
                    progressPercentage: widget.courses[i].completionPercentage,
                  ),
                ),
              );
            },
          ),
        ),

        // Page-dot indicator — only rendered when more than one card
        if (widget.courses.length > 1) ...[
          12.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.courses.length, (i) {
              final isActive = i == _currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.symmetric(horizontal: 3.w),
                width: isActive ? 36.w : 12.w,
                height: 6.h,
                decoration: BoxDecoration(
                  color: isActive ? AppCustomColor.textPrimary : AppCustomColor.textPrimary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(30.r),
                ),
              );
            }),
          ),
        ] else
          12.verticalSpace,
      ],
    );
  }
}

/// Recommended courses section: heading row + horizontal scroll of 160px cards.
class _RecommendedSection extends StatelessWidget {
  final VoidCallback? onSeeAll;

  const _RecommendedSection({this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row — "Recommended" + "See all"
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                context.l10n.home.homeRecommended,
                style: AppStyle.textBold20.copyWith(color: AppCustomColor.textPrimary),
              ),
              Semantics(
                button: true,
                label: context.l10n.home.homeRecommendedSeeAll,
                child: GestureDetector(
                  onTap: onSeeAll,
                  child: AppText(
                    context.l10n.home.homeRecommendedSeeAll,
                    style: AppStyle.textBold12.copyWith(color: AppCustomColor.brandPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
        12.verticalSpace,

        // Horizontal scroll of compact course cards
        BlocSelector<HomeCubit, HomeState, List<SuggestedCourseEntity>>(
          selector: (state) => state.suggestedCourses,
          builder: (context, courses) {
            if (courses.isEmpty) return const SizedBox.shrink();

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(left: 20.w, right: 4.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < courses.length; i++) ...[
                    _RecommendedCard(course: courses[i]),
                    if (i < courses.length - 1) 16.horizontalSpace,
                  ],
                ],
              ),
            );
          },
        ),
        20.verticalSpace,
      ],
    );
  }
}

/// Compact 160×160 course card for the Recommended horizontal scroll.
class _RecommendedCard extends StatelessWidget {
  final SuggestedCourseEntity course;

  const _RecommendedCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: course.title.text,
      child: GestureDetector(
        onTap: () {
          // Navigate: resolve the course in HomeCubit then go to roadmap
          final didSelect = context.read<HomeCubit>().trySelectCourseFromCourseId(course.id);
          if (didSelect) {
            context.read<CourseRoadmapCubit>().setRoadmapSource('home_recommended');
            CourseRoadmapRoute().go(context);
            // Not just setCurrentIndex(1) — see course_card.dart's identical fix.
            context.read<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
          } else {
            context.read<CourseCubit>()
              ..setAllCourseSource('home_recommended')
              ..resetExploreToAll();
            // Fall back to the Explore grid — switch shell branch, don't push.
            context.read<PageCubit>().setCurrentIndex(3);
            CourseRoute().go(context);
          }
        },
        child: SizedBox(
          width: 160.w,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail container with badge overlay
              Container(
                width: 160.w,
                height: 160.h,
                decoration: BoxDecoration(
                  color: AppCustomColor.backgroundWhite,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppCustomColor.borderDefault),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // Course image fills the container
                    Positioned.fill(
                      child: CacheNetworkGraphic(
                        url: course.image,
                        fit: BoxFit.cover,
                      ),
                    ),

                    // "New course" badge — top-left corner. Only for courses
                    // that are actually new (manual isNew flag, or within their
                    // scheduled new-course window), not every recommended card.
                    if (course.isNewNow)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppCustomColor.backgroundWhite,
                            borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(12.r),
                            ),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 12.sp,
                                color: const Color(0xFF2B604E),
                              ),
                              4.horizontalSpace,
                              AppText(
                                context.l10n.home.homeRecommendedNewCourse,
                                style: AppStyle.textBold12.copyWith(
                                  color: const Color(0xFF2B604E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              8.verticalSpace,

              // Course title — 2 lines max
              AppText(
                course.title.text,
                style: AppStyle.textBold12.copyWith(
                  color: AppCustomColor.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
