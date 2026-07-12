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
  /// (the course grid, "My courses", "View more", or search). Only these show a
  /// back button. Other sources (Courses tab default, Home cards) show none.
  static const _kExploreSources = {
    'course_selection',
    'my_courses',
    'skillset_courses',
    'search',
  };

  /// Returns to wherever the user opened this roadmap from.
  /// CourseCubit/PageCubit aren't provided above the roadmap tree, so resolve
  /// them from DI (see [TopProgressBar]).
  void _backFromRoadmap(BuildContext context, String source) {
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
    // Grid / My courses / search live on the Explore tab — return to it at the
    // current skillset (mirrors the header dropdown's navigation).
    final skillsetIndex =
        AppDI.injector.get<HomeCubit>().state.selectedSkillsetIndex;
    AppDI.injector.get<CourseCubit>()
      ..setAllCourseSource('roadmap_back')
      ..jumpToSkillset(skillsetIndex);
    context.read<PageCubit>().setCurrentIndex(3);
    CourseRoute(selectedTabIndex: skillsetIndex).go(context);
  }

  /// "Go to Habit" entry point (design.md 5.7) — jumps straight to the Habit
  /// tab from the roadmap header.
  void _goToHabit(BuildContext context) {
    HabitRoute().go(context);
    Future.delayed(const Duration(milliseconds: 100), () {
      AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.habit);
    });
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
        unawaited(_maybeShowReanchor(courseId));
      }
    });
  }

  /// Re-anchor prompt (PRD §9.1) — shown once per course when entering its
  /// roadmap, before the user starts learning. Guarded by BTV-authored reasons
  /// existing for the course, so it's a no-op until content is configured.
  Future<void> _maybeShowReanchor(String courseId) async {
    if (courseId.isEmpty) return;
    final habitCubit = AppDI.injector.get<HabitCubit>();
    if (habitCubit.state.reanchorShownCourseIds.contains(courseId)) return;
    final reasons = await habitCubit.getReanchorReasons(courseId);
    if (!mounted || reasons.isEmpty) return;
    if (context.read<PageCubit>().state.currentRouteName != RouteNamed.courseRoadmap) return;
    habitCubit.markReanchorShown(courseId);
    await ReanchorPage.push(context, reasons: reasons);
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
        backgroundColor: AppCustomColor.backgroundWhite,
        body: BlocSelector<CourseRoadmapCubit, CourseRoadmapState, bool>(
          selector: (state) => state.status == CourseRoadmapStatus.loading && state.roadmap.levels.isEmpty,
          builder: (context, isLoading) {
            if (isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppCustomColor.brandPrimary,
                ),
              );
            }
            return SafeBody(
              child: Stack(
                children: [
                  Column(
                    children: [
                      // Header: centered skillset dropdown, plus a back arrow on
                      // the left ONLY when the roadmap was opened from Explore
                      // (grid / My courses / View more / search) — tapping it
                      // returns to that Explore screen. Reached "naturally"
                      // (Courses tab, Home cards) → no back button.
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          const TopProgressBar(),
                          BlocSelector<CourseRoadmapCubit, CourseRoadmapState, String>(
                            selector: (state) => state.roadmapSource,
                            builder: (context, source) {
                              if (!_kExploreSources.contains(source)) {
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
                                      color: AppCustomColor.textPrimary,
                                    ),
                                    onPressed: () => _backFromRoadmap(context, source),
                                  ),
                                ),
                              );
                            },
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Semantics(
                              button: true,
                              label: context.l10n.habit.navLabel,
                              child: IconButton(
                                key: const Key('roadmap-go-to-habit'),
                                padding: EdgeInsets.only(right: 12.w),
                                constraints: const BoxConstraints(),
                                icon: SvgPicture.asset(
                                  AppAsset.svg.common.navGrowth,
                                  width: 22.w,
                                  height: 22.w,
                                  colorFilter: ColorFilter.mode(AppCustomColor.textPrimary, BlendMode.srcIn),
                                ),
                                onPressed: () => _goToHabit(context),
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
                    // Sit above the floating nav bar (≈110.h tall incl. safe area).
                    bottom: 120.h,
                    child: Center(
                      child: CourseRoadmapFloatingButton(
                        onPressed: () {
                          // Empty "My Course" state (no roadmap yet): the CTA
                          // can't start a lesson, so send the user to Explore to
                          // pick a course — mirrors the TopProgressBar dropdown.
                          final hasRoadmap = context
                              .read<CourseRoadmapCubit>()
                              .state
                              .roadmap
                              .levels
                              .isNotEmpty;
                          if (!hasRoadmap) {
                            final skillsetIndex = AppDI.injector
                                .get<HomeCubit>()
                                .state
                                .selectedSkillsetIndex;
                            AppDI.injector.get<CourseCubit>()
                              ..setAllCourseSource('my_course_empty')
                              ..jumpToSkillset(skillsetIndex);
                            context.read<PageCubit>().setCurrentIndex(3);
                            CourseRoute(selectedTabIndex: skillsetIndex)
                                .go(context);
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
