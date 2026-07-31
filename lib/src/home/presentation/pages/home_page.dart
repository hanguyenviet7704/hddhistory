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
        child: Scaffold(
          key: const Key('home-page'),
          // Transparent only when a custom study background is active (so it
          // shows through); otherwise the stock flat lavender is preserved.
          backgroundColor: studyThemeScaffoldColor(context, const Color(0xFFEFEEF9)),
          body: SafeBody(
            // Optional-update header is pinned ABOVE the scroll so it stays
            // fixed while Home content scrolls under it. Shown only when a
            // newer, non-forced version exists and the user hasn't dismissed
            // it this session (see HomeCubit.checkOptionalUpdate).
            child: Column(
              children: [
                BlocSelector<HomeCubit, HomeState, bool>(
                  selector: (state) => state.showUpdateBanner,
                  builder: (context, showUpdateBanner) {
                    if (!showUpdateBanner) return const SizedBox.shrink();
                    return UpdateHeader(
                      onDismiss: () => context.read<HomeCubit>().dismissUpdateBanner(),
                    );
                  },
                ),
                Expanded(
                  child: Stack(
                    children: [
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
                          // Each section owns its own horizontal padding (20) so the
                          // "Jump back in" / "Recommended" horizontal strips can bleed
                          // to the screen edge; only vertical padding lives here.
                          padding: EdgeInsets.only(top: 8.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Greeting ──────────────────────────────────────
                              const _HomeGreeting(),
                              26.verticalSpace,

                              // ── Weekly streak ────────────────────────────────
                              const _HomeWeeklyStreakCard(),
                              26.verticalSpace,

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

                              // ── Motivation quote ─────────────────────────────
                              const HomeQuoteCard(),

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

                              // Bottom padding — clear the floating nav bar and, when
                              // showing, the habit reminder card that floats above it
                              // (see the Positioned below), otherwise the banner stays
                              // clipped under those overlays.
                              BlocBuilder<HabitCubit, HabitState>(
                                bloc: AppDI.injector.get<HabitCubit>(),
                                buildWhen: (previous, current) => previous.showHomeReminder != current.showHomeReminder,
                                builder: (context, state) {
                                  final extra = state.showHomeReminder ? 8.h + 80.h + 16.h : 16.h;
                                  return SizedBox(height: floatingNavBarHeight(context) + extra);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Habit check-in reminder — floats above the bottom nav
                      // (PRD §9.4). Renders nothing when there's nothing to check in.
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: floatingNavBarHeight(context) + 8.h,
                        child: const HomeHabitReminderCard(),
                      ),
                    ],
                  ),
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

// ───────────────────────────────────────────────────────────────────────────
// Greeting
// ───────────────────────────────────────────────────────────────────────────

class _HomeGreeting extends StatelessWidget {
  const _HomeGreeting();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: BlocSelector<ProfileCubit, ProfileState, String>(
        selector: (state) => state.user.name,
        builder: (context, username) {
          final firstName = username.trim().split(' ').first;
          final greeting = firstName.isEmpty ? context.l10n.home.homeGreetingPrefix : '${context.l10n.home.homeGreetingPrefix}, $firstName';
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      greeting,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyle.text14.copyWith(
                        fontSize: 15.sp,
                        color: studyThemeOnBg(context, AppCustomColor.streakTextMuted),
                      ),
                    ),
                    2.verticalSpace,
                    AppText(
                      context.l10n.home.homeMindQuestion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _poppins(21, FontWeight.w700, color: studyThemeOnBg(context, AppCustomColor.textPrimary)),
                    ),
                  ],
                ),
              ),
              12.horizontalSpace,
              // Design item 2 — "Change background" affordance in the header.
              const ChangeBackgroundButton(source: 'home'),
            ],
          );
        },
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Weekly streak card
// ───────────────────────────────────────────────────────────────────────────

class _HomeWeeklyStreakCard extends StatelessWidget {
  const _HomeWeeklyStreakCard();

  @override
  Widget build(BuildContext context) {
    // Display-only streak card: tapping it no longer opens the streak detail
    // (removed per request) — it's a passive weekly summary now.
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: studyThemeCardColor(context),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: _homeCardShadow,
        ),
        child: BlocSelector<LearningStreakCubit, LearningStreakState, ({int streak, List<bool> week})>(
          selector: (state) => (
            streak: state.selectedItem.currentStreak,
            week: state.selectedItem.normalizedWeekStudy,
          ),
          builder: (context, data) {
            return Column(
              children: [
                // Header is always the motivational prompt (design copy),
                // not an "N days streak" count — the streak itself is shown
                // by the day dots below.
                AppText(
                  context.l10n.home.homeStreakEmptyPrompt,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: AppStyle.text12.copyWith(
                    fontSize: 13.sp,
                    color: AppCustomColor.streakTextMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                14.verticalSpace,
                StreakWeekBar(weekStudy: data.week),
              ],
            );
          },
        ),
      ),
    );
  }
}

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
// Quick tiles: Explore 60+ topics · Today's habit
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
                  color: AppCustomColor.brandPrimary,
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
          AppHaptic.select();
          final homeCubit = context.read<HomeCubit>();
          // skill_id/skill_name aren't on SuggestedCourseEntity beyond its
          // skillsetId; resolve the human-readable name from the loaded
          // skillsets (best-effort — empty when the skillset isn't cached).
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
            },
          );
          final didSelect = homeCubit.trySelectCourseFromCourseId(course.id);
          if (didSelect) {
            context.read<CourseRoadmapCubit>().setRoadmapSource('home_recommended');
            CourseRoadmapRoute().go(context);
            context.read<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
          } else {
            context.read<CourseCubit>()
              ..setAllCourseSource('home_recommended')
              ..resetExploreToAll();
            context.read<PageCubit>().setCurrentIndex(3);
            CourseRoute().go(context);
          }
        },
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
            ],
          ),
        ),
      ),
    );
  }
}
