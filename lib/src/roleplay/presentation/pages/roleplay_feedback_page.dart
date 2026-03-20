part of '../../roleplay.dart';

class RoleplayFeedbackPage extends StatefulWidget {
  const RoleplayFeedbackPage({super.key});

  @override
  State<RoleplayFeedbackPage> createState() => _RoleplayFeedbackPageState();
}

class _RoleplayFeedbackPageState extends State<RoleplayFeedbackPage> {
  final ScrollController _scrollController = ScrollController();
  bool _hasTrackedView = false;
  bool _hasTrackedScroll = false;
  bool _hasTrackedScrollBottom = false;
  bool _hasShownFeedbackPopup = false;
  bool _hasSubmittedProgress = false;
  bool _isHandlingPrimaryCta = false;

  void _trackResultView() {
    if (_hasTrackedView) return;
    final trackingData = RoleplayTrackingData.fromContext();
    if (trackingData == null) return;
    AppService.instance.appTrackingService.trackRoleplayResultScrView(trackingData);
    _hasTrackedView = true;
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final trackingData = RoleplayTrackingData.fromContext();
    if (trackingData == null) return;
    final position = _scrollController.position;

    if (!_hasTrackedScroll && position.userScrollDirection != ScrollDirection.idle) {
      AppService.instance.appTrackingService.trackRoleplayResultScroll(trackingData);
      _hasTrackedScroll = true;
    }

    if (!_hasTrackedScrollBottom && position.pixels >= position.maxScrollExtent - 16) {
      AppService.instance.appTrackingService.trackRoleplayResultScroll(trackingData);
      _hasTrackedScrollBottom = true;
    }
  }

  void _maybeFinishRoleplayLesson(RoleplayState state) {
    if (_hasSubmittedProgress) return;
    final progressCubit = AppDI.injector.get<ProgressCubit>();
    if (progressCubit.state.currentLessonResult.reviews.isNotEmpty) return;
    if (state.status == RoleplayStatus.loading && state.feedback.feedbackText.isEmpty) return;

    context.read<RoleplayPointCubit>().finishRoleplayLesson(
      lessonReview: state.feedback.feedbackText,
    );
    _hasSubmittedProgress = true;
  }

  Future<void> _handlePrimaryCta() async {
    if (_isHandlingPrimaryCta) return;
    setState(() => _isHandlingPrimaryCta = true);

    try {
      final trackingData = RoleplayTrackingData.fromContext();
      if (trackingData != null) {
        AppService.instance.appTrackingService.trackRoleplayResultContinue(trackingData);
      }

      await _handleLearningStreakGate();
      if (!mounted) return;

      AppDI.injector.get<CourseRoadmapCubit>().setRoadmapSource('nav_course');
      CourseRoadmapRoute().go(context);
      AppDI.injector.get<PageCubit>().setCurrentIndex(1);
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackResultView();
      context.read<FeedbackCubit>().loadUserFeedbacks();
      _maybeFinishRoleplayLesson(context.read<RoleplayCubit>().state);
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<FeedbackCubit, FeedbackState>(
          listenWhen: (previous, current) => previous.status != current.status && current.status == FeedbackStatus.success,
          listener: (context, state) {
            if (_hasShownFeedbackPopup) return;
            if (state.userFeedback.userHasRoleplayFeedbackComplete) return;
            final trackingData = RoleplayTrackingData.fromContext();
            if (trackingData == null) return;
            _hasShownFeedbackPopup = true;
            FeedbackCompleteLessonPopup.show(
              context,
              entry: FeedbackEntry.roleplay,
              courseId: trackingData.course.id,
              lessonId: trackingData.lesson.id,
              keypointId: trackingData.learningItem.keypointId,
            );
          },
        ),
        BlocListener<RoleplayCubit, RoleplayState>(
          listenWhen: (previous, current) => previous.status != current.status || previous.feedback.feedbackText != current.feedback.feedbackText,
          listener: (context, state) {
            _maybeFinishRoleplayLesson(state);
          },
        ),
      ],
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: AppCustomColor.backgroundGray,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RoleplayFeedbackChart(),
                        RoleplayFeedbackBreakdownSection(),
                        24.verticalSpace,
                        RoleplayFeedbackSummarySection(),
                      ],
                    ),
                  ),
                ),
                RoleplayFeedbackBottomCTA(
                  onPressed: _handlePrimaryCta,
                  label: context.l10n.roleplay.rolePlayResultStartLearningButton,
                  helperText: context.l10n.roleplay.rolePlayHelperTextStartLearnButton,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
