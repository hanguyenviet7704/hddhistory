part of '../../lesson.dart';

class KeypointCompletePage extends StatefulWidget {
  const KeypointCompletePage({super.key});

  @override
  State<KeypointCompletePage> createState() => _KeypointCompletePageState();
}

class _KeypointCompletePageState extends State<KeypointCompletePage> {
  /// Coach có mời sau keypoint này hay không — null khi server chưa trả lời.
  ///
  /// Owner chốt 2026-09-04: sau keypoint chỉ còn MỘT màn, là lời mời của Coach.
  /// Nên khối "Hoàn thành bài học!" bên dưới giờ là PHAO, chỉ vẽ khi Coach tắt
  /// — không có nó thì một user không bật Coach xong bài sẽ đứng trên màn trống
  /// không có đường đi tiếp.
  bool? _coachWillInvite;
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
                      // Chỉ vẽ khi đã biết Coach KHÔNG mời. Lúc chưa biết thì
                      // để trống: hiện khối này rồi một giây sau bị dialog phủ
                      // lên đúng là cái owner yêu cầu bỏ.
                      if (_coachWillInvite == false) ...[
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const _LessonCompleteIllustration(),
                                24.verticalSpace,
                                // Design: `muRise .45s ease .3s both` — the .3s delay is the
                                // leading dead zone of the Interval.
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: 1),
                                  duration: const Duration(milliseconds: 750),
                                  curve: const Interval(0.4, 1, curve: Curves.easeOut),
                                  builder: (context, t, child) => Opacity(
                                    opacity: t,
                                    child: Transform.translate(offset: Offset(0, 12 * (1 - t)), child: child),
                                  ),
                                  child: AppText(
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
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Practice now → the hub. Deliberately NOT gated on the keypoint
                        // having questions: the hub also carries the coming-soon modes,
                        // and Quiz itself guards an empty deck.
                        //
                        // Absent for a GENERATED lesson: the hub's practice is built
                        // from authored exercises, and an imported lesson has none, so
                        // the button would open a mode with nothing in it. Continuing
                        // becomes the primary action instead of a text link, because
                        // with the practice gone it is the only one.
                        if (!lessonState.selectedLesson.isImported) ...[
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
                        ],
                        // Skip kicks off async work (streak gate + habit-suggestion
                        // fetch) before navigating — show a spinner so the button isn't
                        // a dead tap for that beat.
                        Semantics(
                          button: true,
                          child: _ContinueCta(
                            // Filled and full-width when it stands alone; the quiet
                            // text link only makes sense as the second choice under
                            // "Practice now". And "Skip to next lesson" is the wrong
                            // words with nothing to skip.
                            isPrimary: lessonState.selectedLesson.isImported,
                            isBusy: _isHandlingPrimaryCta,
                            onTap: _isHandlingPrimaryCta ? null : () => _handlePrimaryCta(lessonState, continueToNext: true),
                          ),
                        ),
                      ],
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
                  if (mounted) setState(() => _coachWillInvite = willInvite);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Continue" — a text link under Practice, a filled button when it is alone.
///
/// One widget rather than two branches at the call site because the two forms
/// share everything that matters: the same action, the same async gate (the
/// tap kicks off a streak check and a habit-suggestion fetch before it can
/// navigate), and the same spinner so neither reads as a dead tap for that beat.
class _ContinueCta extends StatelessWidget {
  const _ContinueCta({
    required this.isPrimary,
    required this.isBusy,
    required this.onTap,
  });

  final bool isPrimary;
  final bool isBusy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brand = studyThemeOnBg(context, AppCustomColor.brandPrimary);

    final label = isBusy
        ? SizedBox(
            width: 18.w,
            height: 18.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isPrimary ? AppCustomColor.textWhite : brand,
            ),
          )
        : AppText(
            isPrimary ? context.l10n.common.kContinue : context.l10n.lesson.lessonCompleteSkip,
            style: isPrimary
                ? AppStyle.text16.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppCustomColor.textWhite,
                  )
                // Design 15/600 — the app scale has no 15.
                : TextStyle(
                    fontFamily: AppFont.mulish,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: brand,
                  ),
          );

    if (!isPrimary) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(height: 44.h, alignment: Alignment.center, child: label),
      );
    }

    return Material(
      color: AppCustomColor.brandPrimary,
      borderRadius: BorderRadius.circular(999.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(999.r),
        onTap: onTap,
        child: Container(height: 56.h, alignment: Alignment.center, child: label),
      ),
    );
  }
}

/// The design's illustration with its full choreography (`showComplete`'s
/// inline SVG + keyframes): the main report card rises in, the back card
/// follows, the two text bars grow out to the right, the check disc pops with
/// an overshoot, the tick DRAWS itself, and the two sparkles twinkle forever —
/// all while the whole block floats gently. Delays and durations are the
/// design's own (.1/.25/.5/.62/.74/1.0s on a shared clock).
///
/// Laid out in the SVG's 267×120 viewBox coordinates inside a [FittedBox], so
/// every x/y below is the design file's number verbatim.
class _LessonCompleteIllustration extends StatefulWidget {
  const _LessonCompleteIllustration();

  @override
  State<_LessonCompleteIllustration> createState() => _LessonCompleteIllustrationState();
}

class _LessonCompleteIllustrationState extends State<_LessonCompleteIllustration> with TickerProviderStateMixin {
  /// One clock for the staged entry; element delays become [Interval]s on it.
  static const _introMs = 1450;
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _introMs),
  )..forward();

  /// `muFloat 4s ease-in-out infinite` — a gentle bob of the whole block.
  late final AnimationController _float = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);

  /// `muTwinkle` — the two sparkles pulse on different periods (2.4s / 2.8s)
  /// so they never sync up.
  late final AnimationController _twinkleA = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  late final AnimationController _twinkleB = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);

  /// Design delay/duration in ms → an eased slice of the intro clock.
  Animation<double> _stage(int delayMs, int durationMs, [Curve curve = Curves.easeOut]) {
    return CurvedAnimation(
      parent: _intro,
      curve: Interval(delayMs / _introMs, (delayMs + durationMs) / _introMs, curve: curve),
    );
  }

  @override
  void dispose() {
    _intro.dispose();
    _float.dispose();
    _twinkleA.dispose();
    _twinkleB.dispose();
    super.dispose();
  }

  /// `muRise`: fade in while drifting up into place.
  Widget _rise(Animation<double> t, Widget child) {
    return AnimatedBuilder(
      animation: t,
      builder: (context, child) => Opacity(
        opacity: t.value,
        child: Transform.translate(offset: Offset(0, 12 * (1 - t.value)), child: child),
      ),
      child: child,
    );
  }

  /// `muSlideRight`: grow out of the left edge (the design pins the
  /// transform-origin to the bar's own x).
  Widget _slideRight(Animation<double> t, Widget child) {
    return AnimatedBuilder(
      animation: t,
      builder: (context, child) => Opacity(
        opacity: t.value,
        child: Transform.scale(scaleX: t.value, alignment: Alignment.centerLeft, child: child),
      ),
      child: child,
    );
  }

  /// `muPop`: scale in with the design's overshoot (cubic-bezier(.2,.9,.3,1.4)).
  Widget _pop(Animation<double> t, Widget child) {
    return AnimatedBuilder(
      animation: t,
      builder: (context, child) => Opacity(
        opacity: t.value.clamp(0, 1),
        child: Transform.scale(scale: t.value, child: child),
      ),
      child: child,
    );
  }

  /// `muTwinkle`: opacity + scale pulse.
  Widget _twinkle(AnimationController controller, Widget child) {
    final t = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
    return AnimatedBuilder(
      animation: t,
      builder: (context, child) => Opacity(
        opacity: 0.25 + 0.75 * t.value,
        child: Transform.scale(scale: 0.7 + 0.3 * t.value, child: child),
      ),
      child: child,
    );
  }

  Widget _roundedRect({required double width, required double height, required double radius, required Color color}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (context, child) => Transform.translate(offset: Offset(0, -3.h * _float.value), child: child),
      child: SizedBox(
        width: 290.w,
        child: FittedBox(
          child: SizedBox(
            width: 267,
            height: 122,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Back report card (rises second).
                Positioned(
                  left: 61.16,
                  top: 63.16,
                  child: _rise(_stage(250, 500), _roundedRect(width: 177.61, height: 48, radius: 12, color: const Color(0x99EBEAFD))),
                ),
                // Main report card (first in).
                Positioned(
                  left: 33.93,
                  top: 1,
                  child: _rise(
                    _stage(100, 500),
                    Container(
                      width: 232.07,
                      height: 90.21,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBEAFD),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: AppCustomColor.backgroundWhite, width: 2),
                      ),
                    ),
                  ),
                ),
                // The two text bars grow out to the right, staggered.
                Positioned(left: 57.93, top: 20.5, child: _slideRight(_stage(500, 450), _roundedRect(width: 55, height: 12, radius: 6, color: const Color(0xFFD6CAFD)))),
                Positioned(left: 57.93, top: 40.5, child: _slideRight(_stage(620, 450), _roundedRect(width: 120, height: 12, radius: 6, color: const Color(0x66D6CAFD)))),
                // Check disc pops with overshoot, then the tick draws itself.
                Positioned(
                  left: 32.93 - 18.82,
                  top: 41.28 - 18.82,
                  child: _pop(
                    _stage(740, 500, Curves.easeOutBack),
                    Container(
                      width: 18.82 * 2,
                      height: 18.82 * 2,
                      decoration: const BoxDecoration(color: Color(0xFF4B44CA), shape: BoxShape.circle),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  child: CustomPaint(
                    size: const Size(267, 122),
                    painter: _DrawnCheckPainter(progress: _stage(1000, 450)),
                  ),
                ),
                // Sparkles.
                Positioned(
                  left: 4.67 - 2.44,
                  top: 20.94 - 2.44,
                  child: _twinkle(
                    _twinkleA,
                    Container(
                      width: 4.89,
                      height: 4.89,
                      decoration: const BoxDecoration(color: Color(0xFFC7C5FA), shape: BoxShape.circle),
                    ),
                  ),
                ),
                Positioned(
                  left: 4,
                  top: 1.7,
                  child: _twinkle(_twinkleB, CustomPaint(size: const Size(16.7, 16.7), painter: const _SparklePainter())),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The tick inside the check disc, revealed along its own length — the design's
/// `muDraw` (`stroke-dasharray: 30` animated to offset 0). Painted in the same
/// 267×120 canvas so the path coordinates are the SVG's verbatim.
class _DrawnCheckPainter extends CustomPainter {
  const _DrawnCheckPainter({required this.progress}) : super(repaint: progress);

  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress.value <= 0) return;
    final path = ui.Path()
      ..moveTo(25.44, 40.93)
      ..lineTo(30.66, 46.28)
      ..lineTo(40.44, 36.28);
    final paint = Paint()
      ..color = AppCustomColor.backgroundWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.67
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress.value), paint);
    }
  }

  @override
  bool shouldRepaint(_DrawnCheckPainter oldDelegate) => false;
}

/// The four-point sparkle star, drawn as a concave diamond in its own local
/// box (the SVG path's bounding box).
class _SparklePainter extends CustomPainter {
  const _SparklePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    const pinch = 0.16;
    final path = ui.Path()
      ..moveTo(cx, cy - r)
      ..quadraticBezierTo(cx + r * pinch, cy - r * pinch, cx + r, cy)
      ..quadraticBezierTo(cx + r * pinch, cy + r * pinch, cx, cy + r)
      ..quadraticBezierTo(cx - r * pinch, cy + r * pinch, cx - r, cy)
      ..quadraticBezierTo(cx - r * pinch, cy - r * pinch, cx, cy - r)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFC7C5FA));
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) => false;
}
