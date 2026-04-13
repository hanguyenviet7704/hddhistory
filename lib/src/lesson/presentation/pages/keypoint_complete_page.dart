part of '../../lesson.dart';

class KeypointCompletePage extends StatefulWidget {
  const KeypointCompletePage({super.key});

  @override
  State<KeypointCompletePage> createState() => _KeypointCompletePageState();
}

class _KeypointCompletePageState extends State<KeypointCompletePage> {
  bool _hasShownFeedbackPopup = false;
  bool _isHandlingPrimaryCta = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
      }

      await _handleLearningStreakGate();
      if (!mounted) return;
      _navigateAfterCompletion(lessonState);
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

  void _navigateAfterCompletion(CourseLessonState lessonState) {
    if (lessonState.wasLessonCompletedBefore) {
      CourseRoadmapRoute().go(context);
      Future.delayed(const Duration(milliseconds: 100), () {
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
      });
      return;
    }
    BadgeProgressRoute().go(context);
    Future.delayed(const Duration(milliseconds: 100), () {
      AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.badgeProgress);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lessonState = context.select((CourseLessonCubit cubit) => cubit.state);
    final currentTitle = lessonState.currentTitle;
    final currentLessonForNext = lessonState.currentLessonForNext;
    final nextLesson = context.select(
      (CourseRoadmapCubit cubit) => cubit.state.roadmap.nextLessonAfter(currentLessonForNext),
    );
    final nextTitle = nextLesson.displayTitleForNextLesson;

    return BlocListener<FeedbackCubit, FeedbackState>(
      listenWhen: (previous, current) => previous.status != current.status && current.status == FeedbackStatus.success,
      listener: (context, state) {
        if (_hasShownFeedbackPopup) return;
        if (state.userFeedback.userHasKeypointFeedbackComplete) return;

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
        FeedbackCompleteLessonPopup.show(
          context,
          entry: FeedbackEntry.keypoint,
          courseId: courseId,
          lessonId: lessonId,
          keypointId: keypointId,
        );
      },
      child: Scaffold(
        backgroundColor: AppCustomColor.backgroundWhite,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: CompletionHeaderCard(title: currentTitle),
                        ),
                      ),
                      if (nextLesson.id.isNotEmpty && nextTitle.isNotEmpty) NextLessonCard(title: nextTitle),
                    ],
                  ),
                ),
              ),
              LessonCompletionPrimaryButton(
                label: context.l10n.exercise.exerciseCompleteKeypointSkipButton,
                onPressed: () => _handlePrimaryCta(lessonState),
                margin: EdgeInsets.only(bottom: 16.h, top: 16.h),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
