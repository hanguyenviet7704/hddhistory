part of '../../course.dart';

class CourseRoadmapPage extends StatefulWidget {
  const CourseRoadmapPage({super.key});

  @override
  State<CourseRoadmapPage> createState() => _CourseRoadmapPageState();
}

/// Roadmap-source values that mean the user opened this roadmap FROM Explore
/// (the course grid, "View more", or search) or from a Profile-pushed page
/// ("My courses", the Achievements badge detail). These show a back button;
/// 'my_courses' / 'setting_badge' get dedicated returns in `_backFromRoadmap`
/// (re-open the root-pushed page over the Profile tab), the rest fall through
/// to the Explore screen.
@visibleForTesting
const roadmapExploreSources = {
  'course_selection',
  'my_courses',
  'skillset_courses',
  'search',
  'setting_badge',
};

/// Roadmap-source values that mean the user opened this roadmap from a Home
/// course card (or straight out of onboarding). These also show a back button,
/// but it returns to the Home tab — there's no Explore screen behind them (see
/// `_backFromRoadmap`). The bare "Courses tab default" / roleplay returns
/// (source 'nav_course') are deliberately NOT included, so those keep showing no
/// back button.
///
/// EVERY source a Home entry point passes to `setRoadmapSource` has to be listed
/// here, or that entry point strands the user on a roadmap with no way back.
/// That is exactly how 'home_new_today' shipped broken.
@visibleForTesting
const roadmapHomeSources = {
  'home_continue_learning',
  'home_recommended',
  'home_new_today',
  'onboarding',
};

/// Roadmap-source values that mean the user opened this roadmap from the Habit
/// tab — today only the "Đọc thêm" rail inside a habit's detail sheet. Back
/// returns to the Habit tab (see `_backFromRoadmap`).
///
/// That rail pops the sheet before it navigates, so there is nothing left to
/// come back to on its own: without a registration here the tap ends on a
/// roadmap with no way out, which is how it shipped.
///
/// Back lands on the Habit tab, NOT on the reopened detail sheet — restoring
/// the sheet would mean carrying the [UserHabitEntity] through the roadmap, and
/// the tracker row it was opened from is right there on the tab.
@visibleForTesting
const roadmapHabitSources = {'habit_detail'};

/// Whether the roadmap renders its back button for [source]. Kept pure and
/// top-level so the source→back-button contract is testable without standing up
/// the whole roadmap widget tree.
@visibleForTesting
bool roadmapShowsBackButton(String source) =>
    roadmapExploreSources.contains(source) || roadmapHomeSources.contains(source) || roadmapHabitSources.contains(source);

class _CourseRoadmapPageState extends State<CourseRoadmapPage> {
  bool _hasTrackedForVisibility = false;
  String _lastTrackedCourseId = '';
  String _lastLoadedProgressCourseId = '';

  /// Returns to wherever the user opened this roadmap from.
  /// CourseCubit/PageCubit aren't provided above the roadmap tree, so resolve
  /// them from DI (see [TopProgressBar]).
  void _backFromRoadmap(BuildContext context, String source) {
    // Learning-flow spec: roadmap_back. Best-effort course/skill context.
    final backCourseId = context.read<CourseRoadmapCubit>().state.roadmap.courseId;
    final backTrackingData = CourseTrackingData.fromCourseId(context, backCourseId);
    AppService.instance.appTrackingService.trackEvent(
      TrackingKey.roadmapBack,
      parameters: backTrackingData == null
          ? null
          : {
              'skill_id': backTrackingData.skillset.id,
              'skill_name': backTrackingData.skillset.trackingName,
              'course_id': backTrackingData.course.id,
              'course_name': backTrackingData.course.trackingName,
            },
    );
    // Opened from a Home card or straight out of onboarding — there's no
    // Explore screen behind it, so back returns to the Home tab.
    if (roadmapHomeSources.contains(source)) {
      final page = context.read<PageCubit>();
      page.setCurrentIndex(0); // Home branch
      HomeRoute().go(context);
      page.setCurrentRouteName(RouteNamed.home);
      return;
    }
    // Opened from a habit's "Đọc thêm" rail — the sheet was popped on the way
    // out, so return to the Habit tab it belonged to.
    if (roadmapHabitSources.contains(source)) {
      final page = context.read<PageCubit>();
      page.setCurrentIndex(4); // Habit branch
      const HabitRoute().go(context);
      page.setCurrentRouteName(RouteNamed.habit);
      return;
    }
    // "View more" opened the full one-skillset grid (SkillsetCoursesRoute, a
    // child of the roadmap route) — go back to that exact page.
    if (source == 'skillset_courses') {
      final skillsetId = AppDI.injector.get<HomeCubit>().state.currentSkillset.id;
      if (skillsetId.isNotEmpty) {
        SkillsetCoursesRoute(skillsetId: skillsetId).go(context);
        context.read<PageCubit>().setCurrentRouteName(RouteNamed.skillsetCourses);
        return;
      }
    }
    // Opened from Profile → "My course" (a root-pushed page, not a branch).
    // Return there: switch to the Profile tab, then re-open the page over it.
    if (source == 'my_courses') {
      final page = context.read<PageCubit>();
      page.setCurrentIndex(2); // Setting/Profile branch
      ProfileRoute().go(context);
      page.setCurrentRouteName(RouteNamed.profile);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = AppConfig.instance.context;
        if (ctx != null) MyCoursesPage.open(ctx);
      });
      return;
    }
    // Opened from Profile → Achievements badge detail ("Đi đến khoá học"), a
    // root-pushed page like My courses. Return there: switch to the Profile
    // tab, then re-open the Achievements page over it.
    if (source == 'setting_badge') {
      final page = context.read<PageCubit>();
      page.setCurrentIndex(2); // Setting/Profile branch
      ProfileRoute().go(context);
      page.setCurrentRouteName(RouteNamed.profile);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = AppConfig.instance.context;
        if (ctx != null) AchievementsFullPage.open(ctx);
      });
      return;
    }
    // Grid / search live on the Explore tab — return to it at the
    // current skillset (mirrors the header dropdown's navigation).
    final skillsetIndex = AppDI.injector.get<HomeCubit>().state.selectedSkillsetIndex;
    AppDI.injector.get<CourseCubit>()
      ..setAllCourseSource('roadmap_back')
      ..jumpToSkillset(skillsetIndex);
    context.read<PageCubit>().setCurrentIndex(3);
    CourseRoute(selectedTabIndex: skillsetIndex).go(context);
  }

  void _trackRoadmapQuickLearningClick(String startType) {
    final roadmapState = context.read<CourseRoadmapCubit>().state;
    final courseId = roadmapState.roadmap.courseId;
    if (courseId.isEmpty) return;
    final trackingData = CourseTrackingData.fromCourseId(context, courseId);
    if (trackingData == null) return;
    AppService.instance.appTrackingService.trackRoadmapQuickLearningClick(
      trackingData,
      startType: startType,
    );
  }

  void _trackRoadmapScrView() {
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
    if (context.read<PageCubit>().state.currentRouteName != RouteNamed.courseRoadmap) return;
    final roadmapState = context.read<CourseRoadmapCubit>().state;
    final courseId = roadmapState.roadmap.courseId;
    if (courseId.isEmpty) return;
    if (_hasTrackedForVisibility && _lastTrackedCourseId == courseId) return;
    final trackingData = CourseTrackingData.fromCourseId(context, courseId);
    if (trackingData == null) return;
    AppService.instance.appTrackingService.trackRoadmapScrView(
      trackingData,
      roadmapSource: roadmapState.roadmapSource,
    );
    _lastTrackedCourseId = courseId;
    _hasTrackedForVisibility = true;
  }

  void _loadProgressForRoadmap(String courseId, {bool force = false}) {
    if (courseId.isEmpty) return;
    if (!force && _lastLoadedProgressCourseId == courseId) return;
    _lastLoadedProgressCourseId = courseId;
    unawaited(context.read<ProgressCubit>().loadAllUserProgresss(courseId: courseId, silent: true));
  }

  String _lastCheckedWarmUpCourseId = '';

  /// Resolves whether the "Let's warm up" return-refresher CTA should show for
  /// the course the roadmap just loaded. Runs silently — a failure or "not
  /// due" result simply leaves the floating CTA in its normal start/continue
  /// lesson state (see [CourseRoadmapFloatingButton]).
  void _checkWarmUpForRoadmap(String courseId) {
    if (courseId.isEmpty || _lastCheckedWarmUpCourseId == courseId) return;
    _lastCheckedWarmUpCourseId = courseId;
    unawaited(AppDI.injector.get<WarmUpCubit>().check(courseId));
  }

  /// Surfaces (and keeps fresh) the "resume this course" Live Activity while
  /// this roadmap is the visible screen, so leaving the app FROM the roadmap —
  /// not just mid-lesson — still shows the lesson card. Started while
  /// foreground so it's already live when the user backgrounds. LessonCubit
  /// decides start/update/end (incl. no card once the course is finished).
  void _ensureRoadmapLiveActivity(String courseId) {
    if (courseId.isEmpty) return;
    if (context.read<PageCubit>().state.currentRouteName != RouteNamed.courseRoadmap) return;
    unawaited(AppDI.injector.get<LessonCubit>().ensureLiveActivityForRoadmap(courseId));
  }

  /// Completes a Live Activity resume that asked for a specific keypoint: the
  /// deeplink lands here (the roadmap is what loads course data), and the lesson
  /// opens as soon as that data can resolve the keypoint.
  ///
  /// Returns without consuming the request while the roadmap can't resolve it
  /// yet — a cold start races the fetch, and a later emission retries.
  void _tryResumePendingKeypoint(CourseRoadmapState state) {
    final roadmapCubit = context.read<CourseRoadmapCubit>();
    final keypointId = roadmapCubit.pendingResumeKeypointId;
    if (keypointId.isEmpty) return;

    final lesson = findLessonByKeypointId(state.roadmap, keypointId);
    if (lesson == null) return;

    final keypoint = lesson.keypoints.firstWhere((item) => item.id == keypointId, orElse: KeypointEntity.new);
    if (keypoint.id.isEmpty) return;
    roadmapCubit.clearPendingResumeKeypointId();

    // A stale card must never walk past lesson lock: the paywall config or the
    // user's premium state can have changed since the card was raised, so this
    // re-checks exactly what the roadmap's own tap path checks and otherwise
    // leaves the reader on the roadmap.
    final paywallConfig = AppDI.injector.get<IapCubit>().resolvedPaywallConfig;
    final isPremium = context.read<ProfileCubit>().state.user.isPremium;
    if (state.roadmap.isLessonLocked(lesson, paywallConfig, isPremium: isPremium)) {
      LogDev.info('Live activity resume: keypoint $keypointId is locked, staying on the roadmap');
      return;
    }

    startKeypointLesson(
      lessonCubit: AppDI.injector.get<LessonCubit>(),
      courseLessonCubit: context.read<CourseLessonCubit>(),
      roadmapCubit: roadmapCubit,
      navContext: context,
      lesson: lesson,
      keypoint: keypoint,
      courseLevel: _resolveResumeCourseLevel(state, lesson),
    );
  }

  CourseLevel _resolveResumeCourseLevel(CourseRoadmapState state, LessonEntity lesson) {
    for (final level in state.roadmap.levels) {
      if (level.roadmapLessonsList.any((item) => item.isSameLesson(lesson))) return level.level;
    }
    return state.currentCourseLevel;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<PageCubit>().state.currentRouteName == RouteNamed.courseRoadmap) {
        // Recover from a blank/stale hydrated roadmap (e.g. splash routed here
        // off persisted state without fetching). No-op when data is fresh.
        unawaited(context.read<CourseRoadmapCubit>().ensureRoadmapLoaded());
        _trackRoadmapScrView();
        final courseId = context.read<CourseRoadmapCubit>().state.roadmap.courseId;
        _loadProgressForRoadmap(courseId);
        _checkWarmUpForRoadmap(courseId);
        _ensureRoadmapLiveActivity(courseId);
        // Hydrated roadmap already holds the course → resolve the resume now
        // instead of waiting for a fetch that may never emit a change.
        _tryResumePendingKeypoint(context.read<CourseRoadmapCubit>().state);
      }
    });
  }

  void _tryShowRoleplayIncompleteFeedback(FeedbackState state) {
    final pendingEntry = state.pendingFeedbackIncompletePrompt;
    if (pendingEntry == null) return;
    if (state.status != FeedbackStatus.success) return;
    if (pendingEntry == FeedbackEntry.roleplay && state.userFeedback.userHasRoleplayFeedbackIncomplete) {
      context.read<FeedbackCubit>().clearIncompleteFeedbackPrompt();
      return;
    }
    if (pendingEntry == FeedbackEntry.keypoint && state.userFeedback.userHasKeypointFeedbackIncomplete) {
      context.read<FeedbackCubit>().clearIncompleteFeedbackPrompt();
      return;
    }

    final courseId = state.activeCourseId;
    final lessonId = state.activeLessonId;
    final keypointId = state.activeKeypointId;
    if (courseId.isEmpty && lessonId.isEmpty && keypointId.isEmpty) {
      context.read<FeedbackCubit>().clearIncompleteFeedbackPrompt();
      return;
    }

    context.read<FeedbackCubit>().clearIncompleteFeedbackPrompt();
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (context.read<PageCubit>().state.currentRouteName != RouteNamed.courseRoadmap) return;
      FeedbackIncompleteLessonPopup.show(
        context,
        entry: pendingEntry,
        courseId: courseId,
        lessonId: lessonId,
        keypointId: keypointId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PageCubit, PageState>(
          listenWhen: (previous, current) => previous.currentRouteName != current.currentRouteName,
          listener: (context, state) {
            if (state.currentRouteName == RouteNamed.courseRoadmap) {
              // Returning to the Courses tab with a blank roadmap (initial
              // self-heal also failed) → try again.
              unawaited(context.read<CourseRoadmapCubit>().ensureRoadmapLoaded());
              _trackRoadmapScrView();
              _ensureRoadmapLiveActivity(context.read<CourseRoadmapCubit>().state.roadmap.courseId);
              return;
            }
            _hasTrackedForVisibility = false;
          },
        ),
        BlocListener<CourseRoadmapCubit, CourseRoadmapState>(
          listenWhen: (previous, current) => previous.roadmap.courseId != current.roadmap.courseId,
          listener: (context, state) {
            // Don't reset _hasTrackedForVisibility here: the courseId-changed
            // listener and initState/route-changed listener can both fire for
            // the SAME course on entry, which double-fired roadmap_scr_view.
            // The dedup in _trackRoadmapScrView (_lastTrackedCourseId) already
            // lets a genuinely new course through (last != new id) while
            // blocking a repeat of the same one. The guard is reset only when
            // LEAVING the roadmap route (above), so re-entry re-tracks.
            _trackRoadmapScrView();
            _loadProgressForRoadmap(state.roadmap.courseId);
            _checkWarmUpForRoadmap(state.roadmap.courseId);
            _ensureRoadmapLiveActivity(state.roadmap.courseId);
          },
        ),
        // Separate from the listener above on purpose: a resume also has to fire
        // when the lesson list fills in for a course whose id never changed
        // (hydrated roadmap → fetch lands), and widening that listener's
        // condition would re-run its tracking/progress calls too.
        BlocListener<CourseRoadmapCubit, CourseRoadmapState>(
          listenWhen: (previous, current) =>
              current.roadmap.courseId.isNotEmpty &&
              (previous.roadmap.courseId != current.roadmap.courseId || previous.roadmap.flatLessons.length != current.roadmap.flatLessons.length),
          listener: (context, state) => _tryResumePendingKeypoint(state),
        ),
        BlocListener<FeedbackCubit, FeedbackState>(
          listenWhen: (previous, current) => previous.pendingFeedbackIncompletePrompt != current.pendingFeedbackIncompletePrompt || previous.status != current.status,
          listener: (context, state) {
            _tryShowRoleplayIncompleteFeedback(state);
          },
        ),
        // Each warm-up page sets its own non-primary route name on entry to
        // hide the shell's floating nav (branch nav doesn't fire the root
        // observer). When the flow closes, branch pops likewise don't restore
        // the name, so do it here: if we're still on a warm-up route name,
        // put it back to courseRoadmap (skip when a lesson route took over).
        BlocListener<WarmUpCubit, WarmUpState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) {
            const flowStatuses = {
              WarmUpStatus.intro,
              WarmUpStatus.question,
              WarmUpStatus.result,
              WarmUpStatus.completion,
            };
            if (flowStatuses.contains(state.status)) return;
            const warmUpRouteNames = {
              RouteNamed.warmUpIntro,
              RouteNamed.warmUpQuestion,
              RouteNamed.warmUpCompletion,
            };
            final page = context.read<PageCubit>();
            if (warmUpRouteNames.contains(page.state.currentRouteName)) {
              page.setCurrentRouteName(RouteNamed.courseRoadmap);
            }
            // "Start today's lesson" / "Skip to lesson": the warm-up pages only
            // close the flow and return here; THIS page launches the lesson so
            // the paywall/lesson stacks on the roadmap (dismissing the paywall
            // lands back here, not on a dead-end warm-up screen).
            if (state.isRoutingToLesson) {
              context.read<WarmUpCubit>().setRoutingToLesson(false);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                RoadmapNodeActionHelper.startLastInProgressAction(context);
              });
            }
          },
        ),
      ],
      child: Scaffold(
        // Transparent only when a custom study background is active.
        backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.backgroundWhite),
        body: BlocSelector<CourseRoadmapCubit, CourseRoadmapState, ({CourseRoadmapStatus status, bool hasLevels})>(
          selector: (state) => (
            status: state.status,
            hasLevels: state.roadmap.levels.isNotEmpty,
          ),
          builder: (context, data) {
            // First-ever load for this course (nothing to show yet).
            final isFirstLoad = data.status == CourseRoadmapStatus.loading && !data.hasLevels;
            if (isFirstLoad) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppCustomColor.brandPrimary,
                ),
              );
            }
            // A genuine course switch (different course requested than the one
            // currently on screen — see CourseRoadmapCubit.isSwitchingCourse)
            // fetching in the background: the PREVIOUS course's roadmap is
            // still what's below (loadRoadmap deliberately doesn't clear it),
            // so dim it and overlay a spinner instead of leaving the switch
            // silent or blanking the screen — avoids a jarring
            // blank-then-repopulate flash between two already-familiar
            // courses. Excludes a same-course reload (pull-to-refresh already
            // shows its own spinner; ensureRoadmapLoaded's cold-start
            // self-heal is meant to be invisible).
            final isSwitchingCourse = data.status == CourseRoadmapStatus.loading && context.read<CourseRoadmapCubit>().isSwitchingCourse;
            return SafeBody(
              child: Stack(
                children: [
                  Column(
                    children: [
                      // Header: a back arrow on the left when the roadmap was
                      // opened from Explore (grid / My courses / View more /
                      // search → back to that Explore screen) or from a Home
                      // card / onboarding (→ back to the Home tab); reached
                      // "naturally" (Courses tab default / roleplay return,
                      // source 'nav_course') → no back arrow. Change-theme
                      // button on the right. (The skillset course-switcher
                      // dropdown was removed per design.)
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          BlocSelector<CourseRoadmapCubit, CourseRoadmapState, String>(
                            selector: (state) => state.roadmapSource,
                            builder: (context, source) {
                              if (!roadmapShowsBackButton(source)) {
                                return const SizedBox.shrink();
                              }
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Semantics(
                                  button: true,
                                  label: 'Back',
                                  child: IconButton(
                                    key: const Key('roadmap-back-to-explore'),
                                    padding: EdgeInsets.only(left: 12.w),
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      size: 20.w,
                                      color: studyThemeOnBg(context, AppCustomColor.textPrimary),
                                    ),
                                    onPressed: () {
                                      AppHaptic.select();
                                      _backFromRoadmap(context, source);
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                          // Change-theme affordance — the SAME circular button
                          // + cb-theme glyph as Home, top-right of the roadmap
                          // header. Moved here from the all-courses list (that
                          // placement was redundant); its light circular chrome
                          // stays readable over any custom background.
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: EdgeInsets.only(right: 12.w),
                              child: const ChangeBackgroundButton(
                                key: Key('roadmap-change-theme'),
                                size: 40,
                                source: 'roadmap',
                              ),
                            ),
                          ),
                        ],
                      ),
                      CourseRoadmapContent(),
                    ],
                  ),
                  // Sticky "Start lesson" CTA floating above the bottom nav bar.
                  // (A centerDocked FAB would dock at the screen bottom and sit
                  // behind the floating nav overlay, hiding it.)
                  //
                  // Decorative fade behind the CTA — IgnorePointer so it never
                  // blocks taps on the lesson nodes beneath it. Fades to solid
                  // white on the stock background, but a solid-white block
                  // glares over a custom study background, so fade to a
                  // theme-aware scrim there (soft dark on a dark bg, soft white
                  // on a light one) — enough to separate the CTA without a white
                  // slab.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        height: 200.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _roadmapFadeColor(context).withValues(alpha: 0),
                              _roadmapFadeColor(context),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20.w,
                    right: 20.w,
                    // Clear the nav bar's ACTUAL height (varies with the
                    // device's safe-area inset — 3-button nav reserves far
                    // more than gesture nav) instead of a flat guess, or it
                    // clips on devices with a taller inset.
                    bottom: floatingNavBarHeight(context) + 8.h,
                    child: Center(
                      child: CourseRoadmapFloatingButton(
                        onPressed: () {
                          // Empty "My Course" state (no roadmap yet): the CTA
                          // can't start a lesson, so send the user to Explore to
                          // pick a course — mirrors the TopProgressBar dropdown.
                          final hasRoadmap = context.read<CourseRoadmapCubit>().state.roadmap.levels.isNotEmpty;
                          if (!hasRoadmap) {
                            final skillsetIndex = AppDI.injector.get<HomeCubit>().state.selectedSkillsetIndex;
                            AppDI.injector.get<CourseCubit>()
                              ..setAllCourseSource('my_course_empty')
                              ..jumpToSkillset(skillsetIndex);
                            context.read<PageCubit>().setCurrentIndex(3);
                            CourseRoute(selectedTabIndex: skillsetIndex).go(context);
                            return;
                          }
                          // Return-refresher available for this course: open
                          // the warm-up intro instead of jumping straight into
                          // the last in-progress lesson.
                          final hasWarmUpAvailable = context.read<WarmUpCubit>().state.hasWarmUpAvailable;
                          if (hasWarmUpAvailable) {
                            _trackRoadmapQuickLearningClick('warm_up');
                            context.read<WarmUpCubit>().openIntro();
                            WarmUpIntroRoute().push(context);
                            return;
                          }
                          _trackRoadmapQuickLearningClick('new_lesson');
                          RoadmapNodeActionHelper.startLastInProgressAction(context);
                        },
                      ),
                    ),
                  ),
                  if (isSwitchingCourse) _buildCourseSwitchOverlay(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Dims the stale (previous course's) roadmap and shows a spinner on top
  /// while [isSwitchingCourse] is true — see the call site above. Absorbs
  /// pointer events so a tap mid-switch can't act on the wrong course's node.
  /// End colour of the bottom CTA fade. Solid white on the stock background;
  /// a semi-opaque theme-aware scrim over a custom study background (dark on a
  /// dark bg, soft white on a light one) so the CTA still separates from the
  /// content without stamping a white slab over the personalized background.
  Color _roadmapFadeColor(BuildContext context) {
    if (!studyThemeHasCustomBg(context)) return AppCustomColor.backgroundWhite;
    return studyThemeIsDarkBg(context) ? const Color(0xB3000000) : AppCustomColor.backgroundWhite.op(0.65);
  }

  Widget _buildCourseSwitchOverlay(BuildContext context) {
    // Dim the previous course while switching. A flat white veil glares over a
    // custom study background — a jarring white flash, worst on dark ones — so
    // use a theme-aware scrim (gentle darkening on a dark bg, a soft white haze
    // on a light one) and keep the stock white only when no custom background
    // is active.
    final Color veil = studyThemeHasCustomBg(context) ? (studyThemeIsDarkBg(context) ? const Color(0x66000000) : const Color(0x40FFFFFF)) : AppCustomColor.backgroundWhite.op(0.72);
    return Positioned.fill(
      child: AbsorbPointer(
        child: Container(
          color: veil,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppCustomColor.brandPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
