part of '../../home.dart';

/// Soft shadow shared by every white card on the redesigned Home
/// (design: `0 6px 18px rgba(37,37,37,.05)`).
List<BoxShadow> get _homeCardShadow => [
  BoxShadow(
    color: const Color(0x0D252525),
    offset: Offset(0, 6.h),
    blurRadius: 18.r,
  ),
];

/// Heading/title helper. Uses the app's default font (Mulish, `AppFont.mulish`)
/// so Home matches the rest of the app (e.g. the Habit screens) — the earlier
/// Poppins display font was dropped for a single consistent typeface. Kept as a
/// thin wrapper so the design's heading sizes/weights stay in one place.
TextStyle _poppins(
  double size,
  FontWeight weight, {
  Color color = AppCustomColor.textPrimary,
  double? height,
  double? letterSpacing,
}) => TextStyle(
  fontFamily: AppFont.mulish,
  fontSize: size.sp,
  fontWeight: weight,
  color: color,
  height: height,
  letterSpacing: letterSpacing,
);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with _HomeInAppSurveyMixin, _HomeDailyWarmUpMixin {
  /// How far the reader has dragged the page past its own top, in pixels.
  ///
  /// Home's hero panel starts at y=0 with nothing painted behind it, so a
  /// pull-to-refresh drag slides it down and opens a strip of bare Scaffold —
  /// which is TRANSPARENT under a custom study theme, so the background photo
  /// showed through above the purple ("kéo bị hở"). The strip is filled with
  /// the hero's own gradient, sized from this.
  ///
  /// Measured rather than assumed a fixed height: a static strip behind the
  /// scroll view would keep painting purple once the reader scrolls DOWN, where
  /// the page is deliberately see-through onto the study background.
  final ValueNotifier<double> _pullGap = ValueNotifier<double>(0);

  bool _handlePullGap(ScrollNotification notification) {
    // depth 0 is this page's own vertical scroll view. Home's horizontal strips
    // ("Học tiếp nào", "Gợi ý cho bạn") bubble their notifications through here
    // too, and their offsets have nothing to do with the gap.
    if (notification.depth != 0) return false;
    final metrics = notification.metrics;
    if (metrics.axis != Axis.vertical) return false;

    final gap = (metrics.minScrollExtent - metrics.pixels).clamp(0.0, double.infinity);
    if (gap != _pullGap.value) _pullGap.value = gap;

    return false;
  }

  @override
  void dispose() {
    _pullGap.dispose();
    super.dispose();
  }

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
      // The days 1-7 gift popup used to be triggered from here. It moved to
      // GiftPopupHost on the shell: initState only runs on a cold start, so a
      // reader who resumed MeUp from the background — the ordinary case — never
      // got it. The host watches for resume as well, and owns the cold start
      // this line used to cover.
      // Same recovery for the "Continue learning" my-courses list — it can
      // fail independently of skillsets since both load inside the same
      // Future.wait.
      unawaited(context.read<ProgressCubit>().ensureMyCoursesLoaded());
      // And for the recommended-courses strip, hidden when empty.
      unawaited(context.read<HomeCubit>().ensureSuggestedCoursesLoaded());
      // Optional-update header: surface the pinned banner when a newer,
      // non-forced app version exists (forced updates are gated at splash).
      unawaited(context.read<HomeCubit>().checkOptionalUpdate());
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
    // Already know there's nothing to recap → don't await anything. Without this
    // an account with no active habits still blocked here on a habit fetch whose
    // result is guaranteed to fail the check on the next line (and once the
    // in-memory data goes stale, ensureLoaded() awaits a full round-trip to
    // revalidate a screen this method won't use).
    if (habitCubit.state.status == HabitPageStatus.success && habitCubit.state.activeHabits.isEmpty) return;
    // Otherwise make sure habits are loaded before reading activeHabits (cold
    // start: this runs after the paywall/warm-up gates, but the habit fetch
    // kicked off in initState may not have landed yet).
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
        // Raises the admin-configured promo popup once per app session, after
        // Home has painted. Wraps the Scaffold rather than sitting inside it so
        // the dialog is a sibling of the page content, not a descendant of the
        // scroll view it interrupts.
        child: HomePromoPopupHost(
          child: Scaffold(
            key: const Key('home-page'),
            // Transparent only when a custom study background is active (so it
            // shows through); otherwise the stock flat lavender is preserved.
            backgroundColor: studyThemeScaffoldColor(context, const Color(0xFFEFEEF9)),
            // NO SafeBody here, unlike every other tab: the design runs the purple
            // hero panel behind the status bar, so the top inset is paid inside
            // the panel instead (see HomeHero). The update banner, when it shows,
            // takes that inset itself and tells the panel to skip it.
            body: BlocSelector<HomeCubit, HomeState, bool>(
              selector: (state) => state.showUpdateBanner,
              builder: (context, showUpdateBanner) => Column(
                children: [
                  // Optional-update header is pinned ABOVE the scroll so it stays
                  // fixed while Home content scrolls under it. Shown only when a
                  // newer, non-forced version exists and the user hasn't dismissed
                  // it this session (see HomeCubit.checkOptionalUpdate).
                  if (showUpdateBanner)
                    SafeArea(
                      bottom: false,
                      child: UpdateHeader(
                        onDismiss: () => context.read<HomeCubit>().dismissUpdateBanner(),
                      ),
                    ),
                  Expanded(
                    child: Stack(
                      children: [
                        // The hero's gradient, continued into the pull-to-refresh
                        // gap. Behind the scroll view and exactly as tall as the
                        // drag, so at rest (and on any downward scroll) it has
                        // zero height and the page stays see-through onto the
                        // study background — see [_pullGap].
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: ValueListenableBuilder<double>(
                            valueListenable: _pullGap,
                            builder: (context, gap, _) => SizedBox(
                              height: gap,
                              child: const DecoratedBox(decoration: BoxDecoration(gradient: _kHeroGradient)),
                            ),
                          ),
                        ),
                        NotificationListener<ScrollNotification>(
                          onNotification: _handlePullGap,
                          child: RefreshIndicator(
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
                              // Each section owns its own horizontal padding (20) so the
                              // "Jump back in" / "Recommended" horizontal strips can bleed
                              // to the screen edge; only vertical padding lives here.
                              padding: EdgeInsets.zero,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── Hero: greeting + quote + today's new course ──
                                  // One purple panel with the course card lifted out
                                  // of its bottom edge (design "2 · Home").
                                  HomeHero(hasUpdateHeader: showUpdateBanner),
                                  20.verticalSpace,

                                  // ── Admin-configured promo banner ────────────────
                                  // Collapses to zero height (spacing included) when
                                  // disabled/empty — see HomeBannerCard.
                                  const HomeBannerCard(),

                                  // ── Jump back in (in-progress courses) ───────────
                                  BlocBuilder<ProgressCubit, ProgressState>(
                                    // Only myCoursesPageData drives this section — see the
                                    // original buildWhen note: ProgressCubit also emits on
                                    // frequent mid-lesson progress updates we don't need here.
                                    buildWhen: (previous, current) => previous.myCoursesPageData != current.myCoursesPageData,
                                    builder: (context, state) {
                                      // Only surface courses with something left to
                                      // continue — a 100%-complete course drops out.
                                      final inProgress = state.myCourses.where((c) => c.completionPercentage < 100).toList();
                                      if (inProgress.isEmpty) return const SizedBox.shrink();
                                      return Padding(
                                        padding: EdgeInsets.only(bottom: 28.h),
                                        child: _JumpBackInSection(courses: inProgress),
                                      );
                                    },
                                  ),

                                  // ── Quick tiles: Explore · Today's habit ─────────
                                  const _HomeQuickTiles(),
                                  28.verticalSpace,

                                  // ── Recommended ──────────────────────────────────
                                  _RecommendedSection(
                                    onSeeAll: () {
                                      HomeTracking.track(TrackingKey.homeRcmSeeallClick);
                                      context.read<CourseCubit>()
                                        ..setAllCourseSource('home_recommend_view')
                                        ..resetExploreToAll();
                                      // Switch to the Explore shell branch (index 3).
                                      context.read<PageCubit>().setCurrentIndex(3);
                                      CourseRoute().go(context);
                                    },
                                  ),

                                  // ── Got ideas? feedback banner ───────────────────
                                  GotIdeasBanner(onTap: _openInAppSurveyDialog),

                                  // Bottom padding — clear the floating nav bar so the
                                  // banner above is not left under it.
                                  SizedBox(height: floatingNavBarHeight(context) + 16.h),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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

// ───────────────────────────────────────────────────────────────────────────
// Greeting
// ───────────────────────────────────────────────────────────────────────────

// ───────────────────────────────────────────────────────────────────────────
// Jump back in — horizontal in-progress course cards + page dots
// ───────────────────────────────────────────────────────────────────────────

class _JumpBackInSection extends StatefulWidget {
  final List<CourseEntity> courses;

  const _JumpBackInSection({required this.courses});

  @override
  State<_JumpBackInSection> createState() => _JumpBackInSectionState();
}

class _JumpBackInSectionState extends State<_JumpBackInSection> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Slightly less than full width so the next card peeks in, matching the
    // design's snap-scroll strip.
    _pageController = PageController(viewportFraction: 0.9);
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
        AppText(
          context.l10n.home.homeJumpBackIn,
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          style: _poppins(18, FontWeight.w700, color: studyThemeOnBg(context, AppCustomColor.textPrimary)),
        ),
        14.verticalSpace,
        SizedBox(
          // PageView gives each card a tight height, so this box height IS the
          // card height. Trimmed to hug the card's content (~178) — 202 left a
          // chunk of empty white space below the "Continue" button.
          height: 184.h,
          child: PageView.builder(
            controller: _pageController,
            padEnds: false,
            onPageChanged: (i) {
              HomeTracking.track(TrackingKey.homeContinueSwipe, parameters: {'to_index': i});
              setState(() => _currentIndex = i);
            },
            itemCount: widget.courses.length,
            itemBuilder: (context, i) {
              return Padding(
                padding: EdgeInsets.only(left: 20.w, right: 6.w),
                child: _JumpBackInCard(course: widget.courses[i].withSkillset),
              );
            },
          ),
        ),
        if (widget.courses.length > 1) ...[
          14.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.courses.length, (i) {
              final isActive = i == _currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.symmetric(horizontal: 3.w),
                width: isActive ? 22.w : 6.w,
                height: 6.h,
                decoration: BoxDecoration(
                  color: isActive ? AppCustomColor.brandPrimary : AppCustomColor.brandPrimary.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(30.r),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _JumpBackInCard extends StatelessWidget {
  final CourseEntity course;

  const _JumpBackInCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final progress = (course.completionPercentage / 100).clamp(0.0, 1.0);
    return Semantics(
      button: true,
      label: course.title.text,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptic.select();
          HomeTracking.track(TrackingKey.homeContinueCardClick);
          context.read<CourseRoadmapCubit>().setRoadmapSource('home_continue_learning');
          context.read<HomeCubit>()
            ..selectSkillset(course.skillset)
            ..selectCourse(course);
          CourseRoadmapRoute().go(context);
          // .go() to the roadmap branch root doesn't re-fire the route observer,
          // so re-anchor the route name explicitly (mirrors course_card.dart).
          context.read<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
        },
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: studyThemeCardColor(context),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: _homeCardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: Container(
                      width: 96.r,
                      height: 96.r,
                      color: const Color(0xFFE7EAF1),
                      child: CacheNetworkGraphic(
                        url: course.image,
                        width: 96.r,
                        height: 96.r,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  16.horizontalSpace,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText(
                          course.skillset.title.text.toUpperCase(),
                          maxLines: 1,
                          style: AppStyle.text12.copyWith(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: const Color(0xFF7C8AA4),
                          ),
                        ),
                        8.verticalSpace,
                        AppText(
                          course.title.text,
                          maxLines: 2,
                          style: _poppins(16, FontWeight.w600, height: 1.3),
                        ),
                        10.verticalSpace,
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99.r),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8.h,
                            backgroundColor: const Color(0xFFDEDCF5),
                            valueColor: const AlwaysStoppedAnimation(Color(0xFF6C63E8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              14.verticalSpace,
              Container(
                padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 11.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEDFB),
                  borderRadius: BorderRadius.circular(99.r),
                ),
                child: AppText(
                  context.l10n.home.continueLearning,
                  style: _poppins(14, FontWeight.w600, color: AppCustomColor.brandPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Quick tiles: Explore many courses · Today's habit
// ───────────────────────────────────────────────────────────────────────────

class _HomeQuickTiles extends StatelessWidget {
  const _HomeQuickTiles();

  @override
  Widget build(BuildContext context) {
    // Both tiles are top-aligned and size to their own content — no stretch
    // (which needs a bounded height in the vertical scroll) and no
    // IntrinsicHeight (which trips a semantics parent-data assertion when it
    // wraps interactive/Semantics children). A fixed tile height keeps the two
    // cards visually equal regardless of subtitle line count.
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _QuickTile(
              iconSvg: _kQuickSearchSvg,
              iconBackground: const Color(0xFFEEEDFB),
              title: context.l10n.home.homeExploreTopics,
              subtitle: context.l10n.home.homeExploreTopicsSub,
              onTap: () {
                HomeTracking.track(TrackingKey.homeExploreClick);
                context.read<CourseCubit>()
                  ..setAllCourseSource('home_quick_explore')
                  ..resetExploreToAll();
                context.read<PageCubit>().setCurrentIndex(3);
                CourseRoute().go(context);
              },
            ),
          ),
          14.horizontalSpace,
          Expanded(
            child: _QuickTile(
              iconSvg: _kQuickSproutSvg,
              iconBackground: const Color(0xFFE4F1E7),
              title: context.l10n.home.homeTodayHabit,
              subtitle: context.l10n.home.homeTodayHabitSub,
              onTap: () {
                HomeTracking.track(TrackingKey.homeHabitClick);
                AppDI.injector.get<HabitCubit>().setPendingScrSource('home_habit');
                const HabitRoute(source: 'home_habit').go(context);
                // .go() to a shell branch doesn't update PageCubit's index, so
                // set it (→ habit branch 4) after the switch settles — that's
                // what fires HabitPage's habit_scr_view for this entry.
                Future.delayed(const Duration(milliseconds: 100), () {
                  AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.habit);
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Design asset `assets/cat-*`-style inline icons for the two Home quick tiles
/// (search magnifier + growth sprout), taken verbatim from the design markup so
/// the stroke colours match 1:1.
const String _kQuickSearchSvg =
    '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><circle cx="11" cy="11" r="7" stroke="#554FF0" stroke-width="2.2"/><path d="M16.5 16.5L21 21" stroke="#554FF0" stroke-width="2.2" stroke-linecap="round"/></svg>''';
const String _kQuickSproutSvg =
    '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M12 21v-8" stroke="#3F9E5A" stroke-width="2.1" stroke-linecap="round"/><path d="M12 15c0-3.3-2.7-6-6-6-.55 0-1 .45-1 1 0 3.3 2.7 6 6 6" stroke="#3F9E5A" stroke-width="2.1" stroke-linejoin="round"/><path d="M12 13c0-3.9 3.1-7 7-7 .55 0 1 .45 1 1 0 3.9-3.1 7-7 7" stroke="#3F9E5A" stroke-width="2.1" stroke-linejoin="round"/></svg>''';

class _QuickTile extends StatelessWidget {
  final String iconSvg;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickTile({
    required this.iconSvg,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptic.select();
          onTap();
        },
        child: Container(
          // Tall enough for a 2-line title + 2-line subtitle so longer
          // localized titles ("Khám phá 60+ chủ đề") wrap instead of being
          // clipped; both tiles share this height so they stay visually equal.
          height: 172.h,
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: studyThemeCardColor(context),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: _homeCardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(13.r),
                ),
                alignment: Alignment.center,
                child: SvgPicture.string(iconSvg, width: 24.r, height: 24.r),
              ),
              14.verticalSpace,
              AppText(
                title,
                maxLines: 2,
                style: _poppins(15, FontWeight.w600, height: 1.2),
              ),
              2.verticalSpace,
              AppText(
                subtitle,
                maxLines: 2,
                style: AppStyle.text12.copyWith(
                  color: const Color(0xFF7C8AA4),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Recommended courses — horizontal 132×132 tiles
// ───────────────────────────────────────────────────────────────────────────

class _RecommendedSection extends StatelessWidget {
  final VoidCallback? onSeeAll;

  const _RecommendedSection({this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    // Also select [HomeStatus] (not just the list) so an empty list can be
    // told apart: still loading (cold start — show a skeleton) vs. loaded
    // and genuinely empty (hide the section, same as before).
    return BlocSelector<HomeCubit, HomeState, ({List<SuggestedCourseEntity> courses, HomeStatus status})>(
      selector: (state) => (courses: state.suggestedCourses, status: state.status),
      builder: (context, data) {
        final courses = data.courses;
        if (courses.isEmpty) {
          final isColdLoading = data.status == HomeStatus.loading || data.status == HomeStatus.initial;
          return isColdLoading ? _RecommendedSkeleton(onSeeAll: onSeeAll) : const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RecommendedHeader(onSeeAll: onSeeAll),
            14.verticalSpace,
            // Controller-less strip: fire home_rcm_swipe once per gesture on the
            // settle (ScrollEndNotification only fires when scrolling stops, so
            // it can't spam mid-drag).
            NotificationListener<ScrollEndNotification>(
              onNotification: (notification) {
                if (notification.depth == 0) {
                  HomeTracking.track(TrackingKey.homeRcmSwipe);
                }
                return false;
              },
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(left: 20.w, right: 8.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < courses.length; i++) ...[
                      _RecommendedCard(course: courses[i]),
                      if (i < courses.length - 1) 14.horizontalSpace,
                    ],
                  ],
                ),
              ),
            ),
            28.verticalSpace,
          ],
        );
      },
    );
  }
}

/// "Recommended" section header — title + "See all". Shared by the loaded
/// strip and its cold-load skeleton so the two stay pixel-identical (no
/// layout jump when the real content swaps in).
class _RecommendedHeader extends StatelessWidget {
  final VoidCallback? onSeeAll;

  const _RecommendedHeader({this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AppText(
            context.l10n.home.homeRecommended,
            style: _poppins(18, FontWeight.w700, color: studyThemeOnBg(context, AppCustomColor.textPrimary)),
          ),
          Semantics(
            button: true,
            label: context.l10n.home.homeRecommendedSeeAll,
            child: GestureDetector(
              onTap: onSeeAll == null
                  ? null
                  : () {
                      AppHaptic.select();
                      onSeeAll!();
                    },
              child: AppText(
                context.l10n.home.homeRecommendedSeeAll,
                style: AppStyle.textBold12.copyWith(
                  fontSize: 13.sp,
                  // Drawn straight onto the study background, so it needs the
                  // accent lift the heading beside it already gets: the stock
                  // deep purple sinks into a dark photo and the link went
                  // unreadable. `studyThemeAccentOnBg` rather than
                  // `studyThemeOnBg` — this has to stay recognisably a link,
                  // not turn into the same white as the title next to it.
                  color: studyThemeAccentOnBg(context, AppCustomColor.brandPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cold-load placeholder for the "Recommended" strip (first open, nothing
/// cached yet). The header stays live (real copy, "See all" still
/// navigable) — only the course tiles are skeletonized, reusing
/// [_RecommendedCard] fed dummy entities so Skeletonizer auto-generates bone
/// shapes matching the real tile layout (thumbnail + 2-line title).
class _RecommendedSkeleton extends StatelessWidget {
  final VoidCallback? onSeeAll;

  const _RecommendedSkeleton({this.onSeeAll});

  static const int _kSkeletonCardCount = 4;
  static const SuggestedCourseEntity _kSkeletonCourse = SuggestedCourseEntity(
    id: 'skeleton',
    title: BaseMultiLanguage(en: 'Course title placeholder'),
    author: 'Author name',
    viewCount: 6300,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RecommendedHeader(onSeeAll: onSeeAll),
        14.verticalSpace,
        sk.Skeletonizer(
          enabled: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(left: 20.w, right: 8.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < _kSkeletonCardCount; i++) ...[
                  const _RecommendedCard(course: _kSkeletonCourse),
                  if (i < _kSkeletonCardCount - 1) 14.horizontalSpace,
                ],
              ],
            ),
          ),
        ),
        28.verticalSpace,
      ],
    );
  }
}

/// Compact 132×132 course tile for the Recommended horizontal scroll.
/// Opens a suggested course: straight to its roadmap when the catalog can
/// resolve it, otherwise into Explore. Shared by the Recommended strip and the
/// "New today" card so both report the same tracking shape and behave
/// identically on a course the catalog has not loaded.
void _openSuggestedCourse(
  BuildContext context,
  SuggestedCourseEntity course, {
  required String source,
}) {
  AppHaptic.select();
  final homeCubit = context.read<HomeCubit>();
  // skill_id/skill_name aren't on SuggestedCourseEntity beyond its skillsetId;
  // resolve the human-readable name from the loaded skillsets (best-effort —
  // empty when the skillset isn't cached).
  final skillset = homeCubit.state.skillsets.firstWhere(
    (s) => s.id == course.skillsetId || s.courses.any((c) => c.id == course.id),
    orElse: () => const SkillsetEntity(),
  );
  HomeTracking.track(
    TrackingKey.homeRcmCardClick,
    parameters: {
      'course_id': course.id,
      'course_name': course.title.text,
      'skill_id': course.skillsetId.isNotEmpty ? course.skillsetId : skillset.id,
      'skill_name': skillset.title.text,
      'source': source,
    },
  );
  final didSelect = homeCubit.trySelectCourseFromCourseId(course.id);
  if (didSelect) {
    context.read<CourseRoadmapCubit>().setRoadmapSource(source);
    CourseRoadmapRoute().go(context);
    context.read<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
  } else {
    context.read<CourseCubit>()
      ..setAllCourseSource(source)
      ..resetExploreToAll();
    context.read<PageCubit>().setCurrentIndex(3);
    CourseRoute().go(context);
  }
}

/// The one big course tile under the quote — "New today".
///
/// Shows the NEWEST course for real — latest `createdAt` wins (user call,
/// 2026-08-04) — so the card is the same for everyone and only changes when
/// the content team actually publishes something. Courses served by an older
/// API/cache carry no `createdAt`; those fall back to the previous behavior,
/// a calendar-day-seeded pick (stable within the day, no mid-scroll
/// reshuffle), rather than a blank card.
class _NewTodayCard extends StatelessWidget {
  final SuggestedCourseEntity course;

  const _NewTodayCard({required this.course});

  /// The card keeps the design's plain WHITE fill even over a custom study
  /// background, where every other Home card turns translucent: it is the one
  /// surface lifted onto the purple header, and a see-through panel there would
  /// read as part of the header instead of as a card sitting on it.
  static const List<BoxShadow> _shadow = [
    BoxShadow(color: Color(0x2914103C), blurRadius: 34, offset: Offset(0, 16)),
  ];

  /// The image carries a shadow of its own (design), which is what lifts it off
  /// the white card behind it.
  static const List<BoxShadow> _imageShadow = [
    BoxShadow(color: Color(0x470B082D), blurRadius: 22, offset: Offset(0, 10)),
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: course.title.text,
      child: GestureDetector(
        key: const Key('home-new-today-card'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptic.select();
          _openSuggestedCourse(context, course, source: 'home_new_today');
        },
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundWhite,
            borderRadius: BorderRadius.circular(22.r),
            boxShadow: _shadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Square and full width of the card: the artwork is the reason
              // this section is a big card and not another list row.
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE7EAF1),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: _imageShadow,
                ),
                clipBehavior: Clip.antiAlias,
                // 8:7, which is what the design MOCKUP draws — its CSS declares
                // `aspect-ratio:1/1` but the canvas renderer ignores that and
                // falls back to the artwork's own ratio, so a square here stood
                // ~35pt taller than the picture and pushed "Jump back in" off
                // the first screen ("tỷ lệ sai với thiết kế", 2026-08-13).
                // FIXED either way: admin uploads arbitrary artwork, and letting
                // the image decide its own height would move every section below.
                child: AspectRatio(
                  aspectRatio: 8 / 7,
                  child: CacheNetworkGraphic(url: course.image, fit: BoxFit.cover),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(4.w, 12.h, 4.w, 2.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // The eyebrow says what the removed section heading
                          // used to — from inside the card, so the card can sit
                          // on the header with no title floating above it.
                          AppText(
                            context.l10n.home.homeNewTodayLabel.toUpperCase(),
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: AppFont.mulish,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.11 * 10.sp,
                              color: AppCustomColor.brandPrimary,
                            ),
                          ),
                          5.verticalSpace,
                          AppText(
                            course.title.text,
                            maxLines: 3,
                            style: TextStyle(
                              fontFamily: AppFont.mulish,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                              color: AppCustomColor.textPrimary,
                            ),
                          ),
                          4.verticalSpace,
                          // Author + reach, both configured per course in admin.
                          _NewTodayMetaRow(course: course, color: const Color(0xFF7C8AA4)),
                        ],
                      ),
                    ),
                    12.horizontalSpace,
                    Container(
                      width: 36.r,
                      height: 36.r,
                      decoration: BoxDecoration(
                        color: AppCustomColor.brandPrimary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppCustomColor.brandPrimary.withValues(alpha: 0.35),
                            blurRadius: 16.r,
                            offset: Offset(0, 8.h),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.chevron_right_rounded, size: 22.r, color: AppCustomColor.textWhite),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Author + view count under the "New today" title, per the design.
///
/// Both come from admin per course and either can be blank, so this renders
/// whichever halves exist and falls back to the lesson count when neither does.
class _NewTodayMetaRow extends StatelessWidget {
  final SuggestedCourseEntity course;
  final Color color;

  const _NewTodayMetaRow({required this.course, required this.color});

  @override
  Widget build(BuildContext context) {
    final author = course.author?.trim() ?? '';
    final views = course.viewCount;

    final parts = <Widget>[
      if (author.isNotEmpty) _NewTodayMetaItem(icon: Icons.edit_outlined, label: author, color: color),
      if (views != null && views > 0)
        _NewTodayMetaItem(
          icon: Icons.visibility_outlined,
          label: _compactCount(views),
          color: color,
        ),
    ];

    if (parts.isEmpty) {
      parts.add(
        _NewTodayMetaItem(
          icon: Icons.menu_book_rounded,
          label: context.l10n.allcourse.lessonsCount(count: course.numberOfLesson),
          color: color,
        ),
      );
    }

    // Left-aligned, like the eyebrow and title it sits under (the card's text
    // block is one left-aligned column in the design).
    return Row(
      children: [
        for (int i = 0; i < parts.length; i++) ...[
          if (i > 0) 12.horizontalSpace,
          parts[i],
        ],
      ],
    );
  }
}

/// One icon + label pair in the "New today" meta row.
class _NewTodayMetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _NewTodayMetaItem({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13.r, color: color),
        4.horizontalSpace,
        AppText(
          label,
          style: TextStyle(
            fontFamily: AppFont.mulish,
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// 6300 -> "6.3k", 1200000 -> "1.2M". The raw number is what admin stores, so
/// the abbreviation is a display concern and lives here.
String _compactCount(int value) {
  if (value >= 1000000) {
    final m = value / 1000000;
    return '${m.toStringAsFixed(m >= 10 ? 0 : 1).replaceFirst(RegExp(r'\.0$'), '')}M';
  }
  if (value >= 1000) {
    final k = value / 1000;
    final rounded = k.toStringAsFixed(k >= 10 ? 0 : 1).replaceFirst(RegExp(r'\.0$'), '');
    // 999_999 rounds to "1000k", which reads as broken — promote it to "1M".
    return rounded == '1000' ? '1M' : '${rounded}k';
  }
  return '$value';
}

class _RecommendedCard extends StatelessWidget {
  final SuggestedCourseEntity course;

  const _RecommendedCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: course.title.text,
      child: GestureDetector(
        onTap: () => _openSuggestedCourse(context, course, source: 'home_recommended'),
        child: SizedBox(
          width: 132.r,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 132.r,
                height: 132.r,
                decoration: BoxDecoration(
                  color: AppCustomColor.brandPrimary50,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppCustomColor.textPrimary.withValues(alpha: 0.08)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CacheNetworkGraphic(
                        url: course.image,
                        fit: BoxFit.cover,
                        // Clip the image itself to the tile's radius too, so the
                        // corners round even if the parent Container's clip is
                        // bypassed (some cached-image render paths ignore it).
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                    if (course.isNewNow)
                      Positioned(
                        top: 10.r,
                        left: 10.r,
                        child: Container(
                          padding: EdgeInsets.fromLTRB(6.w, 4.h, 9.w, 4.h),
                          decoration: BoxDecoration(
                            color: AppCustomColor.backgroundWhite,
                            borderRadius: BorderRadius.circular(99.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 12.r,
                                color: const Color(0xFF2B604E),
                              ),
                              4.horizontalSpace,
                              AppText(
                                context.l10n.home.homeRecommendedNewCourse,
                                style: AppStyle.text10.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2B604E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if ((course.viewCount ?? 0) > 0)
                      Positioned(
                        right: 9.r,
                        bottom: 9.r,
                        child: CourseViewsChip(count: course.viewCount!),
                      ),
                  ],
                ),
              ),
              8.verticalSpace,
              SizedBox(
                width: 132.r,
                child: AppText(
                  course.title.text,
                  maxLines: 2,
                  style: AppStyle.text12.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: studyThemeOnBg(context, AppCustomColor.textPrimary),
                    height: 1.35,
                  ),
                ),
              ),
              if ((course.author?.trim() ?? '').isNotEmpty) ...[
                4.verticalSpace,
                SizedBox(
                  width: 132.r,
                  child: CourseAuthorLine(
                    author: course.author!.trim(),
                    color: studyThemeOnBg(context, kCourseMetaAuthorColor),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
