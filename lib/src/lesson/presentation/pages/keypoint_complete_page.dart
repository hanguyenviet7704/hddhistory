part of '../../lesson.dart';

/// Outcome of the post-keypoint habit-adoption prompt so the caller can route
/// differently: [skipped] ("Skip, keep learning") returns the user to the
/// roadmap instead of the badge/achievement celebration; [navigatedAway] means
/// the prompt already switched branches (Add habit → Habit tab); [other] covers
/// "no prompt shown" / "added but stayed", which keep the normal badge routing.
enum _HabitPromptOutcome { navigatedAway, skipped, other }

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Assert this page's (non-primary) route name so the shell's floating
      // nav pill stays hidden — otherwise it overlaps the primary CTA below.
      _ensureKeypointCompleteRouteName();
      final trackingData = KeypointTrackingData.fromContext();
      if (trackingData == null) return;
      AppService.instance.appTrackingService.trackKeypointFinishScrView(trackingData);
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

  /// Post-lesson habit suggestion (PRD §9.2 Starter/Reflection — one screen,
  /// shown after every keypoint).
  /// - Per-keypoint curated suggestions (BTV-authored, keyed by keypointId).
  /// - FR2.8: skipped if the user already adopted a habit from this keypoint.
  /// - Adopted habits carry sourceKeypointId/sourceCourseId (§9.5 grouping).
  ///
  /// Shows the post-keypoint habit-adoption prompt and reports how it ended
  /// (see [_HabitPromptOutcome]) so [_navigateAfterCompletion] can route
  /// accordingly.
  Future<_HabitPromptOutcome> _maybeShowHabitPrompt(CourseLessonState lessonState) async {
    final habitCubit = AppDI.injector.get<HabitCubit>();
    await habitCubit.ensureLoaded();
    if (!mounted) return _HabitPromptOutcome.other;

    final keypointId = lessonState.currentKeypointId;
    // FR2.8 — each keypoint suggests a habit only once.
    if (keypointId.isNotEmpty && habitCubit.state.userHabits.any((h) => h.sourceKeypointId == keypointId)) {
      return _HabitPromptOutcome.other;
    }

    final suggestions = await habitCubit.loadLibrary(keypointId: keypointId);
    if (!mounted || suggestions.isEmpty) return _HabitPromptOutcome.other;

    final courseId = resolveLessonFlowCourseId(
      lessonCourseId: lessonState.selectedLesson.courseId,
      roadmapCourseId: context.read<CourseRoadmapCubit>().state.roadmap.courseId,
      homeCourseId: context.read<HomeCubit>().state.currentCourse.id,
    );

    final added = await Navigator.of(context).push<bool>(
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
    if (!mounted) return _HabitPromptOutcome.other;
    // "Skip, keep learning" → keep the user learning (return to the roadmap),
    // never detour to the badge/achievement celebration.
    if (added != true) return _HabitPromptOutcome.skipped;

    final goToHabit = await HabitAddedPopup.show(context);
    if (goToHabit != true || !mounted) return _HabitPromptOutcome.other;

    // Leaving to the Habit branch — stop reclaiming this page's route name.
    _navigatedAway = true;
    // First reset THIS (course) branch back to its roadmap, otherwise this
    // completion page lingers on top of the course branch's stack and the user
    // sees it again (stale, 0%) when they tap back to the Course tab. Switching
    // to the Habit branch alone never cleans the course branch. Two branch-level
    // go()s coalesce within one frame, so defer the Habit switch to the next
    // frame; use the global context since this page may be disposed by then.
    CourseRoadmapRoute().go(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = AppConfig.instance.context;
      if (ctx != null) HabitRoute().go(ctx);
      Future.delayed(const Duration(milliseconds: 100), () {
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.habit);
      });
    });
    return _HabitPromptOutcome.navigatedAway;
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
    // the Live Activity must end. Done at the start (before the habit-prompt
    // detour) so it ends on every path, not just the roadmap one. The stateful
    // shell keeps CourseRoadmapPage alive, so its initState can't be relied on
    // to fire on return — hence ending here at the actual session teardown.
    unawaited(AppDI.injector.get<LiveActivityService>().end());
    unawaited(cancelLiveActivityReturnNudge());

    final habitOutcome = await _maybeShowHabitPrompt(lessonState);
    if (habitOutcome == _HabitPromptOutcome.navigatedAway || !mounted) return;

    final roadmapState = context.read<CourseRoadmapCubit>().state;
    final homeState = context.read<HomeCubit>().state;
    final courseId = resolveLessonFlowCourseId(
      lessonCourseId: lessonState.selectedLesson.courseId,
      roadmapCourseId: roadmapState.roadmap.courseId,
      homeCourseId: homeState.currentCourse.id,
    );
    syncHomeSelectionForLessonFlowCourse(courseId);

    // Leaving this page — stop reclaiming its route name (see [_navigatedAway]).
    _navigatedAway = true;
    // "Skip, keep learning" always returns to the roadmap — bypass the badge
    // celebration detour (user feedback: redundant/ugly after skipping). Other
    // outcomes keep the normal "badge just completed" celebration.
    if (habitOutcome != _HabitPromptOutcome.skipped && _isCourseLevelBadgeComplete()) {
      BadgeProgressRoute().go(context);
      Future.delayed(const Duration(milliseconds: 100), () {
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.badgeProgress);
      });
      return;
    }

    CourseRoadmapRoute().go(context);
    Future.delayed(const Duration(milliseconds: 100), () {
      AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
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
                onPrimaryCta: () => _handlePrimaryCta(lessonState),
              );
            },
          ),
        ),
      ),
    );
  }
}
