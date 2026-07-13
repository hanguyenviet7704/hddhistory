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
    final skillsetIndex = AppDI.injector.get<HomeCubit>().state.selectedSkillsetIndex;
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

  /// Courses whose Re-anchor check is mid-flight (between passing the guards
  /// and the ReanchorPage being dismissed). The three triggers below can fire
  /// concurrently; without a synchronous claim they all clear the pre-await
  /// guard and each push a ReanchorPage — the reported "re-anchor shows twice".
  /// This blocks any overlapping trigger for the same course immediately, and
  /// stays claimed the whole time the prompt is on screen.
  final Set<String> _reanchorInFlight = <String>{};

  /// Courses whose Re-anchor check has run to a DEFINITIVE conclusion this
  /// session (shown, or genuinely not needed) — read by [build] to keep the
  /// roadmap content hidden behind the loading spinner until the check
  /// resolves. Without this, the roadmap's own state flips to "loaded" the
  /// moment its (parallel) fetch resolves — often faster than the reasons
  /// fetch — so the full roadmap paints for a frame before Re-anchor is
  /// pushed on top ("roadmap shows first, then re-anchor slides in").
  /// Deliberately NOT marked on a stale/off-route bail (the page isn't even
  /// the visible one then) so a later real, on-route check still runs.
  final Set<String> _reanchorDecidedCourseIds = <String>{};

  void _markReanchorDecided(String courseId) {
    if (!mounted || _reanchorDecidedCourseIds.contains(courseId)) return;
    setState(() => _reanchorDecidedCourseIds.add(courseId));
  }

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
    // Pre-seed the Re-anchor gate synchronously, BEFORE the first build, for a
    // roadmap that's already loaded at mount (kept-alive page, revisited
    // course): without this, every revisit — even a course the user is
    // already deep into — shows a one-frame spinner flash while
    // _maybeShowReanchor's async postFrameCallback catches up. A course still
    // needing the real (reasons-fetch) check is deliberately left undecided
    // here; that path runs below as before.
    final initialRoadmap = context.read<CourseRoadmapCubit>().state.roadmap;
    if (initialRoadmap.courseId.isNotEmpty && initialRoadmap.levels.isNotEmpty) {
      final habitCubit = AppDI.injector.get<HabitCubit>();
      final alreadyShown = habitCubit.state.reanchorShownCourseIds.contains(initialRoadmap.courseId);
      final pastLessonOne = initialRoadmap.levels.fold<int>(0, (sum, l) => sum + l.completedLessons) > 0;
      if (alreadyShown || pastLessonOne) {
        _reanchorDecidedCourseIds.add(initialRoadmap.courseId);
      }
    }
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

  /// Re-anchor prompt (PRD §9.1) — a Lesson-1-only prompt: shown once, before
  /// the user has completed any lesson in the course (Lesson 2+ skips it).
  /// Guarded by BTV-authored reasons existing for the course, so it's a no-op
  /// until content is configured.
  ///
  /// Re-triggered from three places (initState alone misses most cases: this
  /// page is a kept-alive shell branch, and at first mount the roadmap fetch
  /// is usually still in flight, so `levels` is empty and the check bailed
  /// silently — tapping Lesson 1 then went straight into the lesson):
  ///  1. initState — roadmap already loaded (e.g. hydrated) when we mount.
  ///  2. Roadmap load completes / switches course while this page is shown.
  ///  3. Returning to this page after a load that finished in the background.
  /// All cheap guards run before the reasons fetch, so repeat triggers cost
  /// nothing once shown (or once the course has any completed lesson).
  Future<void> _maybeShowReanchor(String courseId) async {
    if (courseId.isEmpty) return;
    // Synchronous re-entrancy guard: bail the instant another trigger is
    // already handling this course (the fetch below awaits, so without this
    // two triggers would both clear the checks and push two prompts).
    if (_reanchorInFlight.contains(courseId)) return;
    final habitCubit = AppDI.injector.get<HabitCubit>();
    if (habitCubit.state.reanchorShownCourseIds.contains(courseId)) {
      _markReanchorDecided(courseId); // already resolved earlier — definitive.
      return;
    }
    // Off-route: this page isn't the visible one right now, so there's
    // nothing to gate — leave undecided so a later, on-route trigger runs the
    // real check (marking "decided" here would wrongly skip that check).
    if (context.read<PageCubit>().state.currentRouteName != RouteNamed.courseRoadmap) return;
    // Only before Lesson 1 — no lesson in the course finished yet (Lesson 2+
    // skips it). Guard against an un-loaded roadmap (empty levels would read as
    // "0 completed" and wrongly show re-anchor on Lesson 2+); the roadmap-load
    // listener re-runs this check once levels arrive. (Stale for this course —
    // leave undecided, same reasoning as the off-route bail above.)
    final roadmap = context.read<CourseRoadmapCubit>().state.roadmap;
    if (roadmap.courseId != courseId || roadmap.levels.isEmpty) return;
    final completedLessons = roadmap.levels.fold<int>(0, (sum, level) => sum + level.completedLessons);
    if (completedLessons > 0) {
      _markReanchorDecided(courseId); // definitive: already past Lesson 1.
      return;
    }

    // Claim the course before the first await — all guards above are
    // synchronous, so no overlapping trigger can slip past this point. Held
    // until the prompt is dismissed; released in `finally`.
    _reanchorInFlight.add(courseId);
    try {
      final reasons = await habitCubit.getReanchorReasons(courseId);
      if (!mounted) return;
      if (reasons.isEmpty) {
        _markReanchorDecided(courseId); // definitive: nothing configured.
        return;
      }
      // Re-check after the await: the user may have already tapped into a
      // lesson, or this course's prompt may have been shown by another trigger.
      if (context.read<PageCubit>().state.currentRouteName != RouteNamed.courseRoadmap) return;
      if (habitCubit.state.reanchorShownCourseIds.contains(courseId)) {
        _markReanchorDecided(courseId); // another trigger just handled it for real.
        return;
      }
      habitCubit.markReanchorShown(courseId);
      // Mark decided BEFORE pushing: the gate only needs to hide the roadmap
      // until a decision exists, and the decision (show it) is made right now.
      _markReanchorDecided(courseId);
      final picked = await ReanchorPage.push(context, reasons: reasons);
      // Remember the picked reason so it can be attached when a habit is later
      // adopted from this course (§9.5 tracker cluster title).
      if (picked != null) habitCubit.setReanchorReason(courseId, picked);
    } finally {
      _reanchorInFlight.remove(courseId);
    }
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
              // The roadmap may have finished loading while another tab was
              // shown (the reanchor trigger below skips when off-route).
              unawaited(_maybeShowReanchor(context.read<CourseRoadmapCubit>().state.roadmap.courseId));
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
        // Re-anchor (§9.1) re-trigger: initState races the roadmap fetch (this
        // kept-alive page mounts before levels arrive), so run the check when
        // the roadmap for a course actually finishes loading — a course switch
        // or an empty→loaded levels transition.
        BlocListener<CourseRoadmapCubit, CourseRoadmapState>(
          listenWhen: (previous, current) => previous.roadmap.courseId != current.roadmap.courseId || (previous.roadmap.levels.isEmpty && current.roadmap.levels.isNotEmpty),
          listener: (context, state) {
            unawaited(_maybeShowReanchor(state.roadmap.courseId));
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
        body: BlocSelector<CourseRoadmapCubit, CourseRoadmapState, ({CourseRoadmapStatus status, bool hasLevels, String courseId})>(
          selector: (state) => (
            status: state.status,
            hasLevels: state.roadmap.levels.isNotEmpty,
            courseId: state.roadmap.courseId,
          ),
          builder: (context, data) {
            // First-ever load for this course (nothing to show yet). Also
            // keep the spinner up (instead of painting the roadmap) until the
            // Re-anchor check has resolved for this course — see
            // _reanchorDecidedCourseIds. Without this, the roadmap's own
            // "loaded" state flips before the (separately awaited) Re-anchor
            // decision lands, so the full roadmap flashes before Re-anchor
            // covers it.
            final isFirstLoadOrReanchorGated = (data.status == CourseRoadmapStatus.loading && !data.hasLevels) ||
                (data.courseId.isNotEmpty && !_reanchorDecidedCourseIds.contains(data.courseId));
            if (isFirstLoadOrReanchorGated) {
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
