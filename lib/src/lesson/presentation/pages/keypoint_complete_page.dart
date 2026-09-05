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

  /// [continueToNext] separates the two ways off this screen: Skip CONTINUES
  /// the flow into the next keypoint, the X is an exit and always leaves for
  /// the roadmap.
  Future<void> _handlePrimaryCta(CourseLessonState lessonState, {required bool continueToNext}) async {
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

      await _navigateAfterCompletion(lessonState, continueToNext: continueToNext);
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

  Future<void> _navigateAfterCompletion(CourseLessonState lessonState, {bool continueToNext = false}) async {
    // Leaving here ends the keypoint session — whichever branch we route to
    // next (badge, roadmap), the lesson is no longer open, so the Live
    // Activity must end. Done first so it ends on every path.
    unawaited(AppDI.injector.get<LiveActivityService>().end());
    unawaited(cancelLiveActivityReturnNudge());

    // A generated lesson is in no course, so the catalogue destinations below
    // are both wrong for it: the last keypoint ends on the lesson's OWN roadmap,
    // which is also where it was opened from. Continue still walks to the next
    // keypoint above — only the EXIT differs.
    if (lessonState.selectedLesson.isImported) {
      _navigatedAway = true;
      if (continueToNext && _startNextKeypoint(lessonState)) return;

      // Continue was tapped but the NEXT part of the plan is not ready (still
      // being written, or still waiting on its narration). Say so — a button
      // that silently drops the reader on the roadmap reads as broken — then
      // exit to the roadmap below, whose "Đang tạo…" nodes unlock themselves.
      if (continueToNext && mounted && _nextKeypointStillGenerating(lessonState)) {
        await NextKeypointGeneratingPopup.show(context);
        if (!mounted) return;
      }

      final userLessonId = UserLessonCourseMapper.lessonIdOf(
        lessonState.selectedLesson.id,
      );

      // Falls back to the shelf when the id cannot be read back out — better a
      // list of lessons than a roadmap route with an empty id.
      if (userLessonId.isEmpty) {
        const MyLessonsRoute().go(context);
        Future.delayed(const Duration(milliseconds: 100), () {
          AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.myLessons);
        });

        return;
      }

      LessonReaderRoute(userLessonId).go(context);
      Future.delayed(const Duration(milliseconds: 100), () {
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.lessonReader);
      });

      return;
    }

    // No habit prompt on this path any more: the habit step moved to WHERE THE
    // DESIGN puts it — between the recap flip card and this screen
    // ([HabitSuggestPage], pushed by [KeypointDoneCard]'s Continue). Prompting
    // again here would ask twice in the same minute, on the reader's way OUT.
    final roadmapState = context.read<CourseRoadmapCubit>().state;
    final homeState = context.read<HomeCubit>().state;
    final courseId = resolveLessonFlowCourseId(
      lessonCourseId: lessonState.selectedLesson.courseId,
      roadmapCourseId: roadmapState.roadmap.courseId,
      homeCourseId: homeState.currentCourse.id,
    );
    syncHomeSelectionForLessonFlowCourse(courseId);

    // Only the moment the course badge finishes still routes through the
    // badge celebration; every other completion lands on the roadmap. With
    // achievements hidden app-wide (kAchievementsEnabled), the celebration is
    // off too — celebrating a badge the app pretends not to have would be the
    // one place it leaks back in.
    _navigatedAway = true;
    final page = AppDI.injector.get<PageCubit>();
    final isBadgeComplete = kAchievementsEnabled && _isCourseLevelBadgeComplete();

    // "Skip" CONTINUES the flow — straight into this lesson's next keypoint.
    // Finishing the lesson's LAST keypoint leaves for the roadmap below.
    if (continueToNext && !isBadgeComplete && _startNextKeypoint(lessonState)) return;
    final destinationRouteName = isBadgeComplete ? RouteNamed.badgeProgress : RouteNamed.courseRoadmap;

    if (isBadgeComplete) {
      BadgeProgressRoute().go(context);
    } else {
      CourseRoadmapRoute().go(context);
    }

    // Claim the destination's route name — which logs its screen_view (e.g.
    // roadmap_scr_view) — once it's the screen the user actually sees.
    Future.delayed(const Duration(milliseconds: 100), () {
      page.setCurrentRouteName(destinationRouteName);
    });
  }

  /// Whether Continue failed because the PLAN promises a next keypoint the
  /// server has not finished (text or narration) — as opposed to the lesson
  /// being genuinely read to the end. Decides the "đang tạo" popup.
  bool _nextKeypointStillGenerating(CourseLessonState lessonState) {
    final userLesson = AppDI.injector.get<UserLessonCubit>().lessonForKeypoint(lessonState.resolvedCurrentKeypoint.id);
    if (userLesson == null) return false;

    final keypoints = lessonState.selectedLesson.keypoints;
    final currentIndex = keypoints.indexWhere(
      (keypoint) => keypoint.id == lessonState.resolvedCurrentKeypoint.id,
    );
    if (currentIndex < 0) return false;

    final nextIndex = currentIndex + 1;

    return nextIndex < userLesson.plannedKeypointCount && !userLesson.keypointReady(nextIndex);
  }

  /// Opens the next keypoint of THIS lesson. Returns false when the just
  /// completed keypoint was the lesson's last — leaving the lesson is the
  /// roadmap's moment, so the caller's fallback routes there.
  bool _startNextKeypoint(CourseLessonState lessonState) {
    final roadmapCubit = context.read<CourseRoadmapCubit>();
    final roadmapState = roadmapCubit.state;

    final lesson = lessonState.selectedLesson;
    final keypoints = lesson.keypoints;
    final currentIndex = keypoints.indexWhere((keypoint) => keypoint.id == lessonState.resolvedCurrentKeypoint.id);
    if (currentIndex < 0 || currentIndex + 1 >= keypoints.length) return false;
    final next = keypoints[currentIndex + 1];
    if (next.id.isEmpty) return false;

    // A generated lesson walks the same keypoint list but cannot be re-entered
    // through the catalogue: its items are held in memory, not served.
    if (lesson.isImported) {
      final userLesson = AppDI.injector.get<UserLessonCubit>().lessonForKeypoint(next.id);
      if (userLesson == null) return false;
      // The next keypoint may exist as TEXT while the background phase still
      // owes it narration (progressive import). Not ready = fall through to the
      // lesson's own roadmap, which shows it as "Đang tạo…" and refetches.
      if (!userLesson.keypointReady(currentIndex + 1)) return false;

      startImportedKeypointLesson(
        lessonCubit: AppDI.injector.get<LessonCubit>(),
        courseLessonCubit: context.read<CourseLessonCubit>(),
        navContext: context,
        userLesson: userLesson,
        keypointIndex: currentIndex + 1,
      );
      return true;
    }

    startKeypointLesson(
      lessonCubit: AppDI.injector.get<LessonCubit>(),
      courseLessonCubit: context.read<CourseLessonCubit>(),
      roadmapCubit: roadmapCubit,
      navContext: context,
      lesson: lesson,
      keypoint: next,
      courseLevel: roadmapState.currentCourseLevel,
    );
    return true;
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
              // Not `isCurrent` alone — this page stays `isCurrent` in its own
              // background branch after a cross-branch move ([_navigatedAway]
              // covers the moves we make ourselves; this covers the rest).
              if (!canAssertOwnRouteName(context)) return;
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
          child: Stack(
            children: [
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 30.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // The design's X leaves for the roadmap — an EXIT, unlike
                      // Skip, which continues into the next keypoint. It still
                      // runs the same completion flow rather than a second,
                      // quieter exit path.
                      // Same chrome as the keypoint header's buttons: the design's
                      // 6%-dark circle vanishes over a ThemedBackground photo.
                      Semantics(
                        button: true,
                        label: context.l10n.common.close,
                        child: GestureDetector(
                          onTap: _isHandlingPrimaryCta ? null : () => _handlePrimaryCta(lessonState, continueToNext: false),
                          behavior: HitTestBehavior.opaque,
                          child: KeypointHeaderButtonChrome(
                            child: Icon(Icons.close, size: 18.w, color: KeypointHeaderChrome.icon),
                          ),
                        ),
                      ),
                      // Owner 2026-09-05: "xoá sạch các màn này đi".
                      //
                      // The celebration — illustration, "Hoàn thành bài học!",
                      // ⟨Luyện tập ngay⟩ and ⟨Bỏ qua, sang bài tiếp theo⟩ — is
                      // gone. It was already only drawn when the Coach declined
                      // to invite, and the reader still hit it mid-conversation
                      // ("tôi đang chat với AI thì bị nhảy về màn này"). A
                      // keypoint the Coach has nothing to say about now walks
                      // straight on from `onResolved` below instead of parking
                      // the reader on a photo with one ✕.
                    ],
                  ),
                ),
              ),
              // Luồng 2/3 — the Coach's invitation after this keypoint (the talk),
              // or after the course's last one (the recap). The server decides
              // whether the Coach is on at all; this decides only when.
              CoachKeypointInvite(
                lessonId: lessonState.selectedLesson.id,
                keypointId: lessonState.resolvedCurrentKeypoint.id,
                courseId: lessonState.selectedLesson.courseId,
                isCourseDone: context.read<CourseRoadmapCubit>().state.roadmap.isAllCurrentRoadmapContentCompleted,
                // Named in the course-complete line. Only when Home's selected
                // course IS this lesson's course — otherwise the line would
                // name whatever the header happens to show.
                courseTitle: context.read<HomeCubit>().state.isSelectedCourse(lessonState.selectedLesson.courseId) ? context.read<HomeCubit>().state.currentCourse.title.text : '',
                quizQuestions: QuizCardAnswer.practiceQuestionsOf(context.read<LessonCubit>().state),
                quizTitle: lessonState.currentTitle,
                onContinue: () => _handlePrimaryCta(lessonState, continueToNext: true),
                onResolved: (willInvite) {
                  if (!mounted) return;
                  // The Coach has nothing to say about this keypoint, and with
                  // the celebration deleted there is nothing else on this page.
                  // Walk on rather than leave the reader on a photo with one ✕.
                  // `_handlePrimaryCta` guards its own re-entry, so a second
                  // resolve cannot start a second navigation.
                  if (willInvite == false) {
                    _handlePrimaryCta(lessonState, continueToNext: true);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}





