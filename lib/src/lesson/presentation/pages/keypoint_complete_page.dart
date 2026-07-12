part of '../../lesson.dart';

class KeypointCompletePage extends StatefulWidget {
  const KeypointCompletePage({super.key});

  @override
  State<KeypointCompletePage> createState() => _KeypointCompletePageState();
}

class _KeypointCompletePageState extends State<KeypointCompletePage> {
  bool _hasShownFeedbackPopup = false;
  bool _isHandlingPrimaryCta = false;

  /// Keeps the floating nav pill hidden while this completion screen is shown.
  /// The pill is gated on [PageStateX.isPrimaryRoute]; pushing/popping the
  /// feedback popup (a named route) can reset the current route name back to a
  /// primary one, so we re-assert it whenever the page regains focus.
  void _ensureKeypointCompleteRouteName() {
    if (!mounted) return;
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
      context.read<FeedbackCubit>().loadUserFeedbacks();
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
  /// Returns `true` if it already navigated the user away (they tapped "Go to
  /// Habit" on the success popup) — [_navigateAfterCompletion] then skips its
  /// own roadmap/badge routing so we don't immediately navigate away again.
  Future<bool> _maybeShowHabitPrompt(CourseLessonState lessonState) async {
    final habitCubit = AppDI.injector.get<HabitCubit>();
    await habitCubit.ensureLoaded();
    if (!mounted) return false;

    final keypointId = lessonState.currentKeypointId;
    // FR2.8 — each keypoint suggests a habit only once.
    if (keypointId.isNotEmpty && habitCubit.state.userHabits.any((h) => h.sourceKeypointId == keypointId)) {
      return false;
    }

    final suggestions = await habitCubit.loadLibrary(keypointId: keypointId);
    if (!mounted || suggestions.isEmpty) return false;

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
    if (added != true || !mounted) return false;

    final goToHabit = await HabitAddedPopup.show(context);
    if (goToHabit != true || !mounted) return false;

    HabitRoute().go(context);
    Future.delayed(const Duration(milliseconds: 100), () {
      AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.habit);
    });
    return true;
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
    final navigatedToHabit = await _maybeShowHabitPrompt(lessonState);
    if (navigatedToHabit || !mounted) return;

    final roadmapState = context.read<CourseRoadmapCubit>().state;
    final homeState = context.read<HomeCubit>().state;
    final courseId = resolveLessonFlowCourseId(
      lessonCourseId: lessonState.selectedLesson.courseId,
      roadmapCourseId: roadmapState.roadmap.courseId,
      homeCourseId: homeState.currentCourse.id,
    );
    syncHomeSelectionForLessonFlowCourse(courseId);

    if (_isCourseLevelBadgeComplete()) {
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
        BlocListener<FeedbackCubit, FeedbackState>(
          listenWhen: (previous, current) => previous.status != current.status && current.status == FeedbackStatus.success,
          listener: (context, state) {
            if (_hasShownFeedbackPopup) return;
            if (state.userFeedback.userHasKeypointFeedbackComplete) return;
            // Product decision: the "how was your lesson?" popup is offered
            // once, on the user's first lesson, then off for good.
            if (state.hasShownFirstCompleteLessonFeedback) return;

            final keypointTracking = KeypointTrackingData.fromContext();
            String courseId = '';
            String lessonId = '';
            String keypointId = '';
            if (keypointTracking != null) {
              courseId = keypointTracking.course.id;
              lessonId = keypointTracking.lesson.id;
              keypointId = keypointTracking.keypoint.id;
            } else {
              final lessonState = AppDI.injector.get<CourseLessonCubit>().state;
              courseId = lessonState.selectedLesson.courseId;
              lessonId = lessonState.selectedLesson.id;
              keypointId = lessonState.currentKeypointId;
            }

            if (courseId.isEmpty || lessonId.isEmpty || keypointId.isEmpty) return;
            _hasShownFeedbackPopup = true;
            context.read<FeedbackCubit>().markFirstCompleteLessonFeedbackShown();
            FeedbackCompleteLessonPopup.show(
              context,
              entry: FeedbackEntry.keypoint,
              courseId: courseId,
              lessonId: lessonId,
              keypointId: keypointId,
            ).whenComplete(_ensureKeypointCompleteRouteName);
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
