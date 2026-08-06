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

      await _navigateAfterCompletion(lessonState);
    } finally {
      if (mounted) {
        setState(() => _isHandlingPrimaryCta = false);
      }
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
    // context/cubits are valid) but DON'T show it yet — see below.
    // Behaviour: the add-habit sheet re-appears on EVERY completion of a
    // keypoint (including every re-learn) as long as the user has NOT yet
    // adopted a habit sourced from that keypoint; once they adopt one (it
    // stamps sourceKeypointId == keypointId), it stops appearing for that
    // keypoint. There is deliberately no "suggested once" flag — the adopted
    // habit itself is the gate.
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
    final page = AppDI.injector.get<PageCubit>();
    final isBadgeComplete = _isCourseLevelBadgeComplete();
    final destinationRouteName = isBadgeComplete ? RouteNamed.badgeProgress : RouteNamed.courseRoadmap;

    if (isBadgeComplete) {
      BadgeProgressRoute().go(context);
    } else {
      CourseRoadmapRoute().go(context);
    }

    // Claim the destination's route name — which logs its screen_view (e.g.
    // roadmap_scr_view) — only once it's the screen the user actually sees.
    // With no habit prompt that's right after the branch switch. With a prompt
    // it's deferred until the prompt is dismissed (below), so we never log a
    // roadmap/badge view for a destination immediately covered by the prompt
    // on the root navigator.
    if (suggestions == null || suggestions.isEmpty) {
      Future.delayed(const Duration(milliseconds: 100), () {
        page.setCurrentRouteName(destinationRouteName);
      });
      return;
    }

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
    if (added != true) {
      // Skip → the destination beneath is now the visible screen; claim its
      // route name now so its screen_view (e.g. roadmap_scr_view) logs here —
      // when the roadmap is actually shown, not while the prompt covered it.
      Future.delayed(const Duration(milliseconds: 100), () {
        page.setCurrentRouteName(destinationRouteName);
      });
      return;
    }

    final popupCtx = AppConfig.instance.context;
    if (popupCtx == null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        page.setCurrentRouteName(destinationRouteName);
      });
      return;
    }
    // ignore: use_build_context_synchronously
    final goToHabit = await HabitAddedPopup.show(popupCtx);
    if (goToHabit != true) {
      // Stayed on the destination → claim its route name (logs its view).
      Future.delayed(const Duration(milliseconds: 100), () {
        page.setCurrentRouteName(destinationRouteName);
      });
      return;
    }
    AppDI.injector.get<HabitCubit>().setPendingScrSource('habit_added_scr');
    // ignore: use_build_context_synchronously
    const HabitRoute(source: 'habit_added_scr').go(popupCtx);
    Future.delayed(const Duration(milliseconds: 100), () {
      page.setCurrentRouteName(RouteNamed.habit);
    });
  }

  void _openPractice(BuildContext context, CourseLessonState lessonState) {
    AppHaptic.select();
    final questions = QuizCardAnswer.practiceQuestionsOf(context.read<LessonCubit>().state);
    PracticeHubPage.push(context, title: lessonState.currentTitle, questions: questions);
  }

  @override
  Widget build(BuildContext context) {
    final lessonState = context.select((CourseLessonCubit cubit) => cubit.state);

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
      // Design "3 · Learning" → Lesson complete: X top-left, the floating
      // stacked-cards illustration with a drawn check, "Lesson complete!", and
      // "Practice now" over "Skip to next lesson". It replaced the badge-progress
      // reuse that used to render here (Figma 10326:35300); the badge "complete"
      // celebration is still reachable — [_navigateAfterCompletion] routes
      // through [BadgeProgressRoute] the moment the course badge finishes.
      child: Scaffold(
        key: const Key('keypoint-complete-page'),
        backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.backgroundBrandSoft),
        body: ThemedBackground(
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 30.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The design's X leaves for the roadmap — same act as skipping,
                  // so it runs the same flow (streak gate + habit suggestion
                  // included) rather than a second, quieter exit path.
                  Semantics(
                    button: true,
                    label: context.l10n.common.close,
                    child: GestureDetector(
                      onTap: _isHandlingPrimaryCta ? null : () => _handlePrimaryCta(lessonState),
                      child: Container(
                        width: 36.w,
                        height: 36.w,
                        decoration: BoxDecoration(
                          color: AppCustomColor.textPrimary.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.close, size: 18.w, color: AppCustomColor.kpOptionText),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _LessonCompleteIllustration(),
                          24.verticalSpace,
                          AppText(
                            context.l10n.lesson.lessonCompleteTitle,
                            textAlign: TextAlign.center,
                            // Design 34/800, -0.01em.
                            style: TextStyle(
                              fontFamily: AppFont.mulish,
                              fontSize: 34.sp,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              letterSpacing: 34 * -0.01,
                              color: studyThemeOnBg(context, AppCustomColor.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Practice now → the hub. Deliberately NOT gated on the keypoint
                  // having questions: the hub also carries the coming-soon modes,
                  // and Quiz itself guards an empty deck.
                  Semantics(
                    button: true,
                    child: Material(
                      color: AppCustomColor.brandPrimary,
                      borderRadius: BorderRadius.circular(999.r),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999.r),
                        onTap: () => _openPractice(context, lessonState),
                        child: Container(
                          height: 56.h,
                          alignment: Alignment.center,
                          child: AppText(
                            context.l10n.lesson.lessonCompletePracticeNow,
                            style: AppStyle.text16.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppCustomColor.textWhite,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  10.verticalSpace,
                  // Skip kicks off async work (streak gate + habit-suggestion
                  // fetch) before navigating — show a spinner so the button isn't
                  // a dead tap for that beat.
                  Semantics(
                    button: true,
                    child: GestureDetector(
                      onTap: _isHandlingPrimaryCta ? null : () => _handlePrimaryCta(lessonState),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        height: 44.h,
                        alignment: Alignment.center,
                        child: _isHandlingPrimaryCta
                            ? SizedBox(
                                width: 18.w,
                                height: 18.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: studyThemeOnBg(context, AppCustomColor.brandPrimary),
                                ),
                              )
                            : AppText(
                                context.l10n.lesson.lessonCompleteSkip,
                                // Design 15/600 — the app scale has no 15.
                                style: TextStyle(
                                  fontFamily: AppFont.mulish,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  color: studyThemeOnBg(context, AppCustomColor.brandPrimary),
                                ),
                              ),
                      ),
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
}

/// The design's illustration: two stacked report cards, a drawn check disc and
/// two sparkles (design `showComplete`'s inline SVG, its staged CSS keyframes
/// collapsed into one pop-in + a slow float — the per-element choreography
/// belongs to a prototype, not a production page a reader sees for seconds).
class _LessonCompleteIllustration extends StatefulWidget {
  const _LessonCompleteIllustration();

  @override
  State<_LessonCompleteIllustration> createState() => _LessonCompleteIllustrationState();
}

class _LessonCompleteIllustrationState extends State<_LessonCompleteIllustration> with SingleTickerProviderStateMixin {
  /// The design's `muFloat 4s ease-in-out infinite` — a gentle ±4px bob.
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  static const String _svg = '''
<svg viewBox="0 0 267 120" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="61.1621" y="63.1577" width="177.608" height="48" rx="12" fill="#EBEAFD" opacity="0.6"/>
  <rect x="33.9336" y="1" width="232.066" height="90.2105" rx="11" fill="#EBEAFD" stroke="white" stroke-width="2"/>
  <rect x="57.9336" y="20.5" width="55" height="12" rx="6" fill="#D6CAFD"/>
  <rect x="57.9336" y="40.5" width="120" height="12" rx="6" fill="#D6CAFD" opacity="0.4"/>
  <circle cx="32.93" cy="41.28" r="18.82" fill="#4B44CA"/>
  <path d="M25.4355 40.9344L30.6628 46.2832L40.4355 36.2832" stroke="white" stroke-width="2.66667" stroke-linecap="round" stroke-linejoin="round"/>
  <circle cx="4.66754" cy="20.9449" r="2.44489" fill="#C7C5FA"/>
  <path d="M10.1645 7.85788L11.6958 2.49857C11.9058 1.76362 12.9473 1.76362 13.1573 2.49857L14.6885 7.85788L20.0478 9.38911C20.7828 9.59909 20.7828 10.6406 20.0478 10.8506L14.6885 12.3819L13.1573 17.7412C12.9473 18.4761 11.9058 18.4761 11.6958 17.7412L10.1645 12.3819L4.79114 10.8686C4.05477 10.6612 4.05168 9.61848 4.78682 9.40675L10.1645 7.85788Z" fill="#C7C5FA"/>
</svg>
''';

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: AnimatedBuilder(
        animation: _float,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -4.h * _float.value),
          child: child,
        ),
        child: SvgPicture.string(_svg, width: 290.w),
      ),
    );
  }
}
