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
      _claimRouteOnColdStart();
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
      // Per-skillset achievements, which is what the "Tiến độ học tập" grid
      // divides by. Cache-first inside the cubit, so this paints from the last
      // known values and refreshes behind them.
      context.read<AchievenmentProgressCubit>().loadAllAchievenmentResponses();
      await _prefetchLearningStreak();
      final didOpenPaywall = await _tryOpenPaywallAutoOpen();
      if (didOpenPaywall) return;
      final didOpenWarmUp = await _tryOpenDailyWarmUp();
      if (!didOpenWarmUp) {
        await _loadInAppSurveyConfig();
        if (mounted) _handleSurveyStateChanged(context.read<InAppSurveyCubit>().state);
      }
    });
  }

  /// Claim `home` for the shell — but only if nobody else has.
  ///
  /// `PageState.currentRouteName` starts as `''` and nothing on the way into a
  /// cold start sets it: `PageCubit`'s `case 0` runs on a TAB TAP, and the
  /// first launch is not a tap. Anything keyed on the route name therefore saw
  /// an empty string on the one screen the reader lands on — which is why the
  /// floating Coach bubble was missing from Home until you visited another tab
  /// and came back (owner 2026-09-05: "bong bóng Coach biến mất khỏi màn Trang
  /// chủ"). `isPrimaryRoute` (the floating nav) reads the same field.
  ///
  /// Guarded on empty on purpose: a cold start from a deep link opens straight
  /// into a lesson and has already claimed its own name, and taking it back
  /// here would drop the floating nav onto a full-screen page.
  void _claimRouteOnColdStart() {
    if (!mounted) return;
    final page = context.read<PageCubit>();
    if (page.state.currentRouteName.isNotEmpty) return;
    page.setCurrentRouteName(RouteNamed.home);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PageCubit, PageState>(
      listenWhen: (previous, current) => previous.currentIndex != current.currentIndex,
      listener: (context, state) {
        if (state.currentIndex == 0) {
          // Re-entering the branch by `.go()` changes the index without going
          // through the tab-tap switch, so the name is claimed here too.
          context.read<PageCubit>().setCurrentRouteName(RouteNamed.home);
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
                              // The three progress blocks are on this page now,
                              // so a pull has to refresh them too — otherwise
                              // the half of Home a reader actually pulls FOR
                              // (yesterday's streak, today's square) is the half
                              // that stays stale.
                              context.read<AchievenmentProgressCubit>().loadAllAchievenmentResponses();
                              unawaited(AppDI.injector.get<StudyJournalCubit>().ensureLoaded());
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
                                  // ── Hero: greeting + settings gear + today's new
                                  // course ─────────────────────────────────────────
                                  // One purple panel with the course card lifted out
                                  // of its bottom edge.
                                  HomeHero(hasUpdateHeader: showUpdateBanner),
                                  18.verticalSpace,

                                  // ── The day's quote ──────────────────────────────
                                  // Under the card, not in the header: it reads as a
                                  // caption for the day rather than as a second
                                  // headline competing with the greeting.
                                  const HomeQuote(),

                                  // ── Admin-configured promo banner ────────────────
                                  // Collapses to zero height (spacing included) when
                                  // disabled/empty — see HomeBannerCard.
                                  const HomeBannerCard(),

                                  // "Jump back in" is gone from Home. Every course it
                                  // listed is one tap away in the Library tab, which
                                  // took that job when it took Profile's slot in the
                                  // bottom bar — and the three progress blocks below
                                  // are the answer to "where was I?" this page owes.

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

                                  // ── Progress blocks, moved here from the Profile
                                  // tab (design note 2026-09-04) ───────────────────
                                  const HomeStreakSection(),
                                  const HomeJournalSection(),
                                  const HomeLearningProgressSection(),

                                  // ── Got ideas? feedback banner ───────────────────
                                  20.verticalSpace,
                                  GotIdeasBanner(onTap: _openInAppSurveyDialog),

                                  // Bottom padding — clear the floating nav bar AND the
                                  // coach bubble that floats above it, so the banner
                                  // above is not left under either.
                                  SizedBox(height: floatingNavBarHeight(context) + coachBubbleClearance(context)),
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
            12.verticalSpace,
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
            // Only 4: the next section's heading pays the 28 above it, and two
            // stacked gaps read as a missing section.
            4.verticalSpace,
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
            // Same 15.5/700/-0.1 as every other heading on the page — see
            // [HomeSectionTitle], which this row can't use because it carries
            // a "see all" action beside the title.
            style: _poppins(15.5, FontWeight.w700, letterSpacing: -0.1, color: studyThemeOnBg(context, AppCustomColor.textPrimary)),
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
    BoxShadow(color: Color(0x2414103C), blurRadius: 30, offset: Offset(0, 14)),
  ];

  /// The image carries a shadow of its own (design), which is what lifts it off
  /// the white card behind it.
  static const List<BoxShadow> _imageShadow = [
    BoxShadow(color: Color(0x380B082D), blurRadius: 22, offset: Offset(0, 8)),
  ];

  /// The artwork's own height, fixed rather than derived from a ratio (design
  /// `height:238px`, drawn inside a card of `calc(100% - 52px)` — the two
  /// numbers belong together: widen the card without changing this and the
  /// picture stretches).
  ///
  /// FIXED for the same reason it always was: admin uploads arbitrary artwork,
  /// and letting the image decide its own height would move every section
  /// below it. The redesign shortens it — the card now shares the first screen
  /// with the quote and the banner rather than owning it alone.
  static const double _imageHeight = 238;

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
          // design: padding 12, radius 22.
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundWhite,
            borderRadius: BorderRadius.circular(22.r),
            boxShadow: _shadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full width of the card: the artwork is the reason this section
              // is a big card and not another list row.
              Container(
                height: _imageHeight.h,
                // Explicit, because the height is now fixed rather than derived
                // from an AspectRatio: without a width the Container shrinks to
                // whatever the decoded picture happens to be wide at 238 tall,
                // and the artwork sat in the left two-thirds of the card with
                // white beside it (seen on the simulator 2026-09-04).
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7EAF1),
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: _imageShadow,
                ),
                clipBehavior: Clip.antiAlias,
                child: CacheNetworkGraphic(url: course.image, fit: BoxFit.cover),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(2.w, 10.h, 2.w, 0),
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
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.11 * 9.sp,
                              color: AppCustomColor.brandPrimary,
                            ),
                          ),
                          4.verticalSpace,
                          // Two lines, not three: at 13.5 the title is a label
                          // for the artwork above it, and a third line pushed
                          // the quote below off the first screen.
                          AppText(
                            course.title.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppFont.mulish,
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                              color: AppCustomColor.textPrimary,
                            ),
                          ),
                          4.verticalSpace,
                          // Author + reach, both configured per course in admin.
                          _NewTodayMetaRow(course: course, color: const Color(0xFF7C8AA4)),
                        ],
                      ),
                    ),
                    10.horizontalSpace,
                    Container(
                      width: 30.r,
                      height: 30.r,
                      decoration: BoxDecoration(
                        color: AppCustomColor.brandPrimary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppCustomColor.brandPrimary.withValues(alpha: 0.35),
                            blurRadius: 14.r,
                            offset: Offset(0, 6.h),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.chevron_right_rounded, size: 19.r, color: AppCustomColor.textWhite),
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
          if (i > 0) 10.horizontalSpace,
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
        Icon(icon, size: 12.r, color: color),
        4.horizontalSpace,
        AppText(
          label,
          style: TextStyle(
            fontFamily: AppFont.mulish,
            fontSize: 10.5.sp,
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
