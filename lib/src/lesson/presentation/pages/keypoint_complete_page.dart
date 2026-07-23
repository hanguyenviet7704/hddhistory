part of '../../lesson.dart';

class KeypointCompletePage extends StatefulWidget {
  const KeypointCompletePage({super.key});

  @override
  State<KeypointCompletePage> createState() => _KeypointCompletePageState();
}

class _KeypointCompletePageState extends State<KeypointCompletePage> {
  bool _isHandlingPrimaryCta = false;
  // Set once we intentionally navigate the user off this page to ANOTHER shell
  // branch (e.g. "Go to Habit"). This page stays alive & `isCurrent` in its own
  // background course-branch navigator, so without this flag the reclaim below
  // would keep stealing currentRouteName back to `keypointComplete` and hide
  // the floating nav on the branch we just moved to.
  bool _navigatedAway = false;

  /// Keeps the floating nav pill hidden while this completion screen is shown.
  /// The pill is gated on [PageStateX.isPrimaryRoute]; pushing/popping the
  /// feedback popup (a named route) can reset the current route name back to a
  /// primary one, so we re-assert it whenever the page regains focus — but only
  /// while we're still on this page (not after navigating to another branch).
  void _ensureKeypointCompleteRouteName() {
    if (!mounted || _navigatedAway) return;
    AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.keypointComplete);
  }

  @override
  void initState() {
    super.initState();
    AppHaptic.celebrate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Assert this page's (non-primary) route name so the shell's floating
      // nav pill stays hidden — otherwise it overlaps the primary CTA below.
      _ensureKeypointCompleteRouteName();
      final trackingData = KeypointTrackingData.fromContext();
      if (trackingData == null) return;
      final isDoneCourse = context.read<CourseRoadmapCubit>().state.roadmap.isAllCurrentRoadmapContentCompleted;
      AppService.instance.appTrackingService.trackKeypointFinishScrView(trackingData, isDoneCourse: isDoneCourse);
      if (context.read<LessonCubit>().state.completionOrigin == LessonCompletionOrigin.audio) {
        AppService.instance.appTrackingService.trackKeypointAudioCompleteView(trackingData);
      }
    });
  }

  Future<void> _handlePrimaryCta(CourseLessonState lessonState) async {
    if (_isHandlingPrimaryCta) return;
    setState(() => _isHandlingPrimaryCta = true);

    try {
      final trackingData = KeypointTrackingData.fromContext();
      if (trackingData != null) {
        AppService.instance.appTrackingService.trackKeypointFinishComplete(trackingData);
        if (context.read<LessonCubit>().state.completionOrigin == LessonCompletionOrigin.audio) {
          AppService.instance.appTrackingService.trackKeypointAudioCompleteContinueClick(trackingData);
        }
      }

      await _handleLearningStreakGate();
      if (!mounted) return;
      await _navigateAfterCompletion(lessonState);
    } finally {
      if (mounted) {
        setState(() => _isHandlingPrimaryCta = false);
      }
    }
  }

  Future<void> _handleLearningStreakGate() async {
    final userCubit = AppDI.injector.get<UserCubit>();
    final userState = userCubit.state;
    final learningStreakCubit = AppDI.injector.get<LearningStreakCubit>();
    final nowUtc = DateTime.now().toUtc();
    final gateUtcDay = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);

    if (learningStreakCubit.isSameStreakCountedUtcDay(gateUtcDay)) return;

    final streakResult = await learningStreakCubit.loadUserLearningStreak(
      triggerSource: LearningStreakTriggerSource.completionCta,
      requestedUserId: userState.user.id,
      timeout: const Duration(seconds: 2),
    );

    if (!mounted) return;
    if (!streakResult.isRemoteSuccessWithPositiveStreak) return;
    if (LearningStreakModalGuard.hasBlockingModal(context)) return;

    final committed = await LearningStreakSuccessOverlay.show(
      context,
      streak: streakResult.streak,
    );
    if (!mounted) return;

    if (committed) {
      learningStreakCubit.setLastStreakCountedDate(gateUtcDay);
    }
  }

  /// Whether the course-level badge just became fully unlocked (last
  /// keypoint of its last lesson). Mirrors
  /// `_BadgeProgressPageState._isProgressComplete`. This page always renders
  /// the in-progress badge state itself (see [build]), so on Continue we only
  /// need to special-case the moment the badge finishes: that's the one case
  /// still routed through [BadgeProgressRoute], so the "complete" celebration
  /// (lit badge + congrats Lottie) keeps playing. Every other completion goes
  /// straight to the roadmap.
  bool _isCourseLevelBadgeComplete() {
    final progress = context.read<CourseRoadmapCubit>().state.currentLevelProgress;
    return progress.isCompleted || progress.progress >= 1;
  }

  Future<void> _navigateAfterCompletion(CourseLessonState lessonState) async {
    // Tapping Continue here ends the keypoint session — whichever branch we
    // route to next (Habit, badge, roadmap), the lesson is no longer open, so
    // the Live Activity must end. Done first so it ends on every path.
    unawaited(AppDI.injector.get<LiveActivityService>().end());
    unawaited(cancelLiveActivityReturnNudge());

    // Resolve the per-keypoint habit suggestion up front (while this page's
    // context/cubits are valid) but DON'T show it yet — see below. FR2.8: each
    // keypoint suggests a habit only once.
    final habitCubit = AppDI.injector.get<HabitCubit>();
    await habitCubit.ensureLoaded();
    if (!mounted) return;
    final keypointId = lessonState.currentKeypointId;
    final canSuggest = keypointId.isEmpty || !habitCubit.state.userHabits.any((h) => h.sourceKeypointId == keypointId);
    final suggestions = canSuggest ? await habitCubit.loadLibrary(keypointId: keypointId) : null;
    if (!mounted) return;

    final roadmapState = context.read<CourseRoadmapCubit>().state;
    final homeState = context.read<HomeCubit>().state;
    final courseId = resolveLessonFlowCourseId(
      lessonCourseId: lessonState.selectedLesson.courseId,
      roadmapCourseId: roadmapState.roadmap.courseId,
      homeCourseId: homeState.currentCourse.id,
    );
    syncHomeSelectionForLessonFlowCourse(courseId);

    // Leave this badge-progress completion page for its FINAL destination
    // FIRST, then show the habit prompt on top of that destination. Skipping
    // the prompt then reveals the roadmap/celebration underneath, instead of
    // flashing this page back for a frame during the prompt's pop animation.
    // (Only the moment the course badge finishes still routes through the
    // badge celebration; every other completion lands on the roadmap.)
    _navigatedAway = true;
    if (_isCourseLevelBadgeComplete()) {
      BadgeProgressRoute().go(context);
      Future.delayed(const Duration(milliseconds: 100), () {
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.badgeProgress);
      });
    } else {
      CourseRoadmapRoute().go(context);
      Future.delayed(const Duration(milliseconds: 100), () {
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
      });
    }

    if (suggestions == null || suggestions.isEmpty) return;

    // Habit prompt on the ROOT navigator so it overlays the shell and, on
    // "Skip, keep learning", pops straight back to the destination we just
    // navigated to (never this completion page).
    final ctx = AppConfig.instance.context;
    if (ctx == null) return;
    // ctx is the app-global root context (AppConfig), not this disposed page's
    // — always valid here, so the async-gap lint is a false positive.
    // ignore: use_build_context_synchronously
    final added = await Navigator.of(ctx, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: AppDI.injector.get<HabitCubit>(),
          child: AdoptHabitPage(
            habits: suggestions,
            sourceKeypointId: keypointId,
            sourceCourseId: courseId,
          ),
        ),
      ),
    );
    if (added != true) return; // Skip → stay on the destination above.

    final popupCtx = AppConfig.instance.context;
    if (popupCtx == null) return;
    // ignore: use_build_context_synchronously
    final goToHabit = await HabitAddedPopup.show(popupCtx);
    if (goToHabit != true) return;
    // ignore: use_build_context_synchronously
    HabitRoute().go(popupCtx);
    Future.delayed(const Duration(milliseconds: 100), () {
      AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.habit);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lessonState = context.select((CourseLessonCubit cubit) => cubit.state);
    final currentTitle = lessonState.currentTitle;

    return MultiBlocListener(
      listeners: [
        // Any overlay dismissed above this page (streak, tutorial, dialogs…)
        // makes the route observer write the UNDERLYING route's name — a
        // primary one (shell/roadmap) — which un-hides the floating nav over
        // this page's CTA. The asserts in initState/whenComplete only cover
        // the writers we know about; this listener covers the rest: as long
        // as this page is still the current route, take the name back.
        BlocListener<PageCubit, PageState>(
          bloc: AppDI.injector.get<PageCubit>(),
          listenWhen: (previous, current) => previous.currentRouteName != current.currentRouteName && current.isPrimaryRoute,
          listener: (context, state) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
              _ensureKeypointCompleteRouteName();
            });
          },
        ),
      ],
      child: Scaffold(
        key: const Key('keypoint-complete-page'),
        backgroundColor: AppCustomColor.backgroundWhite,
        body: SafeArea(
          // Reuses the badge-progress design (Figma 10326:35300) so completing
          // a keypoint always shows the course-level badge's current state —
          // grayed badge + progress bar + "N lessons left to unlock" — instead
          // of the old plain checkmark screen. The "complete" step (lit badge
          // + congrats Lottie) is intentionally never shown here: it's only
          // reachable via [BadgeProgressRoute], triggered from
          // [_navigateAfterCompletion] the moment the badge finishes.
          child: BlocSelector<CourseRoadmapCubit, CourseRoadmapState, CourseLevelProgressEntity>(
            selector: (state) => state.currentLevelProgress,
            builder: (context, progress) {
              return _BadgeProgressContent(
                progress: progress,
                step: BadgeProgressStep.inProgress,
                currentTitle: currentTitle,
                // Continue kicks off async work (streak gate + habit-suggestion
                // fetch) before navigating — show a spinner so the button isn't
                // a dead tap for that beat.
                isLoading: _isHandlingPrimaryCta,
                onPrimaryCta: () => _handlePrimaryCta(lessonState),
              );
            },
          ),
        ),
      ),
    );
  }
}
