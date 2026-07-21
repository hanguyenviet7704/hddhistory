part of '../../course.dart';

class CourseRoadmapPage extends StatefulWidget {
  const CourseRoadmapPage({super.key});

  @override
  State<CourseRoadmapPage> createState() => _CourseRoadmapPageState();
}

class _CourseRoadmapPageState extends State<CourseRoadmapPage> {
  bool _hasTrackedForVisibility = false;
  String _lastTrackedCourseId = '';
  String _lastLoadedProgressCourseId = '';

  /// Roadmap-source values that mean the user opened this roadmap FROM Explore
  /// (the course grid, "My courses", "View more", or search). These show a back
  /// button that returns to that Explore screen.
  static const _kExploreSources = {
    'course_selection',
    'my_courses',
    'skillset_courses',
    'search',
  };

  /// Roadmap-source values that mean the user opened this roadmap from a Home
  /// course card (or straight out of onboarding). These also show a back
  /// button, but it returns to the Home tab — there's no Explore screen behind
  /// them (see [_backFromRoadmap]). The bare "Courses tab default" / roleplay
  /// returns (source 'nav_course') are deliberately NOT included, so those keep
  /// showing no back button.
  static const _kHomeSources = {
    'home_continue_learning',
    'home_recommended',
    'onboarding',
  };

  /// Returns to wherever the user opened this roadmap from.
  /// CourseCubit/PageCubit aren't provided above the roadmap tree, so resolve
  /// them from DI (see [TopProgressBar]).
  void _backFromRoadmap(BuildContext context, String source) {
    // Opened from a Home card or straight out of onboarding — there's no
    // Explore screen behind it, so back returns to the Home tab.
    if (_kHomeSources.contains(source)) {
      final page = context.read<PageCubit>();
      page.setCurrentIndex(0); // Home branch
      HomeRoute().go(context);
      page.setCurrentRouteName(RouteNamed.home);
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
    // Grid / search live on the Explore tab — return to it at the
    // current skillset (mirrors the header dropdown's navigation).
    final skillsetIndex = AppDI.injector.get<HomeCubit>().state.selectedSkillsetIndex;
    AppDI.injector.get<CourseCubit>()
      ..setAllCourseSource('roadmap_back')
      ..jumpToSkillset(skillsetIndex);
    context.read<PageCubit>().setCurrentIndex(3);
    CourseRoute(selectedTabIndex: skillsetIndex).go(context);
  }

  void _trackRoadmapQuickLearningClick() {
    final roadmapState = context.read<CourseRoadmapCubit>().state;
    final courseId = roadmapState.roadmap.courseId;
    if (courseId.isEmpty) return;
    final trackingData = CourseTrackingData.fromCourseId(context, courseId);
    if (trackingData == null) return;
    final hasProgress = roadmapState.roadmap.levels.any((level) => level.hasRoadmapProgress);
    final actionType = hasProgress ? 'continue_learning' : 'start_lesson';
    AppService.instance.appTrackingService.trackRoadmapQuickLearningClick(
      trackingData,
      actionType: actionType,
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
            _hasTrackedForVisibility = false;
            _trackRoadmapScrView();
            _loadProgressForRoadmap(state.roadmap.courseId);
            _checkWarmUpForRoadmap(state.roadmap.courseId);
            _ensureRoadmapLiveActivity(state.roadmap.courseId);
          },
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
                      // Header: centered skillset dropdown, plus a back arrow on
                      // the left when the roadmap was opened from Explore
                      // (grid / My courses / View more / search → back to that
                      // Explore screen) or from a Home card / onboarding (→ back
                      // to the Home tab). Reached "naturally" (Courses tab
                      // default / roleplay return, source 'nav_course') → none.
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          const TopProgressBar(),
                          BlocSelector<CourseRoadmapCubit, CourseRoadmapState, String>(
                            selector: (state) => state.roadmapSource,
                            builder: (context, source) {
                              if (!_kExploreSources.contains(source) && !_kHomeSources.contains(source)) {
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
                  // Decorative white fade behind the CTA — IgnorePointer so it
                  // never blocks taps on the lesson nodes beneath it.
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
                              AppCustomColor.backgroundWhite.withValues(alpha: 0),
                              AppCustomColor.backgroundWhite,
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
                            context.read<WarmUpCubit>().openIntro();
                            WarmUpIntroRoute().push(context);
                            return;
                          }
                          _trackRoadmapQuickLearningClick();
                          RoadmapNodeActionHelper.startLastInProgressAction(context);
                        },
                      ),
                    ),
                  ),
                  if (isSwitchingCourse) _buildCourseSwitchOverlay(),
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
  Widget _buildCourseSwitchOverlay() {
    return Positioned.fill(
      child: AbsorbPointer(
        child: Container(
          color: AppCustomColor.backgroundWhite.op(0.72),
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
