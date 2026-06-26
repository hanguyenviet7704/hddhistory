part of '../../lesson.dart';

class LessonPage extends StatefulWidget {
  const LessonPage({
    super.key,
    required this.initialMode,
  });

  final LessonEntryMode initialMode;

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  late final LessonPageController _controller;
  late final LessonReviewBodyBuilder _reviewBodyBuilder;
  late final LessonBodyFactory _bodyFactory;
  late final LessonTimelineBuilder _timelineBuilder;
  late final LessonTrackingDelegate _trackingDelegate;
  late final LessonCubit _lessonCubit;
  late final LessonAudioCubit _lessonAudioCubit;
  late LessonEntryMode _selectedMode;
  bool _hasTrackedAudioShellView = false;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode;
    _lessonCubit = context.read<LessonCubit>();
    _lessonAudioCubit = context.read<LessonAudioCubit>();
    _controller = LessonPageController(
      onBottomButtonVisibilityChanged: (isVisible) => _lessonCubit.setBottomButtonVisible(isVisible),
      onClearSuppressNextAutoScroll: () => _lessonCubit.clearSuppressNextAutoScroll(),
      isMounted: () => mounted,
    );
    _reviewBodyBuilder = const LessonReviewBodyBuilder();
    _bodyFactory = LessonBodyFactory(
      onAnswerChecked: _handleAnswerChecked,
      onContinueUnsupported: () => AppDI.injector.get<ExerciseCubit>().nextQuestion(),
      reviewBodyBuilder: _reviewBodyBuilder,
    );
    _timelineBuilder = const LessonTimelineBuilder();
    _trackingDelegate = const LessonTrackingDelegate();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _showLessonNavigationPopupIfNeeded();
      await _syncAudioKeypoint(context.read<CourseLessonCubit>().state.resolvedCurrentKeypoint);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentKeypoint = context.select((CourseLessonCubit cubit) => cubit.state.resolvedCurrentKeypoint);

    return MultiBlocListener(
      listeners: [
        BlocListener<CourseLessonCubit, CourseLessonState>(
          listenWhen: (previous, current) => previous.resolvedCurrentKeypoint != current.resolvedCurrentKeypoint,
          listener: (context, state) async {
            await _syncAudioKeypoint(state.resolvedCurrentKeypoint);
          },
        ),
        BlocListener<LessonAudioCubit, LessonAudioState>(
          listenWhen: (previous, current) => previous.hasCompletedPlayback != current.hasCompletedPlayback && current.hasCompletedPlayback,
          listener: (context, state) {
            context.read<LessonCubit>().completeCurrentKeypoint(
              origin: LessonCompletionOrigin.audio,
              bypassReviewQueue: true,
            );
          },
        ),
        BlocListener<TheoryCubit, TheoryState>(
          listenWhen: (previous, current) {
            return previous.currentDocumentIndex != current.currentDocumentIndex ||
                previous.currentLearningItem.id != current.currentLearningItem.id ||
                previous.currentDocument.id != current.currentDocument.id;
          },
          listener: (context, state) => _trackingDelegate.trackKeypointTheoryScrView(state),
        ),
        BlocListener<ExerciseCubit, ExerciseState>(
          listenWhen: (previous, current) {
            return previous.currentQuestionIndex != current.currentQuestionIndex ||
                previous.currentLearningItem.id != current.currentLearningItem.id ||
                previous.currentQuestion.id != current.currentQuestion.id;
          },
          listener: (context, state) => _trackingDelegate.trackKeypointExerciseScrView(state),
        ),
      ],
      child: BlocBuilder<LessonCubit, LessonState>(
        buildWhen: (previous, current) {
          if (previous.isBottomButtonVisible != current.isBottomButtonVisible) {
            final normalizedPrevious = previous.copyWith(isBottomButtonVisible: current.isBottomButtonVisible);
            return normalizedPrevious != current;
          }
          return true;
        },
        builder: (context, state) {
          final activeBody = _buildActiveBody(context, state);
          final readSurface = LessonReadSurface(
            state: state,
            activeBody: activeBody,
            controller: _controller,
            timelineBuilder: _timelineBuilder,
            buildReviewBody: _bodyFactory.buildReviewBody,
            onTrackCurrentLearningItemScroll: _trackCurrentLearningItemScroll,
          );
          final bottomButton = _bodyFactory.buildBottomButton(context, activeBody);

          final flagButton = _buildFlagButton(context, currentKeypoint);

          if (!currentKeypoint.hasUsableAudio) {
            return LessonShellLayout(
              selectedMode: LessonEntryMode.read,
              onModeSelected: (_) {},
              onClose: () => LessonExitFlow.open(context),
              showModeToggle: false,
              readBody: readSurface,
              audioBody: const SizedBox.shrink(),
              bottom: bottomButton,
              trailing: flagButton,
              isLoading: state.status == LessonStatus.loading,
            );
          }

          final selectedMode = _selectedMode;
          return LessonDualModeLayout(
            selectedMode: selectedMode,
            onModeSelected: _handleModeSelected,
            onClose: () => LessonExitFlow.open(
              context,
              onBeforePopup: () {
                _trackAudioExitIfNeeded();
                context.read<LessonAudioCubit>().pauseForOverlay();
                return Future.value();
              },
            ),
            readBody: readSurface,
            audioBody: const LessonAudioSurface(),
            bottom: selectedMode.isRead ? bottomButton : null,
            trailing: selectedMode.isAudio ? _buildAudioSpeedPill() : flagButton,
            isLoading: state.status == LessonStatus.loading,
          );
        },
      ),
    );
  }

  Future<void> _syncAudioKeypoint(KeypointEntity keypoint) async {
    await _lessonAudioCubit.configure(keypoint);

    if (!keypoint.hasUsableAudio) {
      if (_selectedMode.isAudio && mounted) {
        setState(() => _selectedMode = LessonEntryMode.read);
      }
      return;
    }

    if (_selectedMode.isAudio) {
      _trackAudioShellViewIfNeeded();
      await _lessonAudioCubit.enterAudioMode();
    }
  }

  void _trackAudioShellViewIfNeeded() {
    if (_hasTrackedAudioShellView) return;
    final trackingData = KeypointTrackingData.fromContext();
    if (trackingData == null) return;

    _hasTrackedAudioShellView = true;
    AppService.instance.appTrackingService.trackKeypointAudioScreenView(
      trackingData,
      mode: _selectedMode.routeValue,
    );
  }

  Future<void> _handleModeSelected(LessonEntryMode nextMode) async {
    if (_selectedMode == nextMode) return;

    final trackingData = KeypointTrackingData.fromContext();
    if (nextMode.isRead) {
      await _lessonAudioCubit.pauseForModeSwitch();
    }

    if (!mounted) return;
    setState(() => _selectedMode = nextMode);

    if (trackingData != null) {
      AppService.instance.appTrackingService.trackKeypointAudioModeSwitch(
        trackingData,
        mode: nextMode.routeValue,
        entryPoint: 'in_route_switch',
        audioPosition: nextMode.isRead ? _lessonAudioCubit.state.positionSeconds : null,
      );
    }

    if (nextMode.isAudio) {
      _trackAudioShellViewIfNeeded();
      await _lessonAudioCubit.enterAudioMode();
    }
  }

  Future<void> _openSpeedSheet() async {
    final shouldResume = await _lessonAudioCubit.pauseForSpeedSheet();

    if (!mounted) return;

    await showLessonAudioSpeedSheet(
      context,
      initialSpeed: _lessonAudioCubit.state.speed,
      onSpeedChanged: (speed) {
        final trackingData = KeypointTrackingData.fromContext();
        if (trackingData != null) {
          AppService.instance.appTrackingService.trackKeypointAudioSpeedSelect(
            trackingData,
            speed: speed,
          );
        }
        _lessonAudioCubit.setSpeed(speed);
      },
    );

    await _lessonAudioCubit.restoreAfterSpeedSheet(resumePlayback: shouldResume);
  }

  Widget _buildAudioSpeedPill() {
    return BlocBuilder<LessonAudioCubit, LessonAudioState>(
      buildWhen: (previous, current) => previous.speed != current.speed || previous.status != current.status,
      builder: (context, state) {
        return LessonAudioSpeedPill(
          label: state.speedValueLabel,
          enabled: !state.isLoading,
          onTap: _handleOpenAudioSpeedSheet,
        );
      },
    );
  }

  Widget _buildFlagButton(BuildContext context, KeypointEntity keypoint) {
    return GestureDetector(
      onTap: () => _openReportIssueSheet(context, keypoint),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 36.w,
        height: 36.w,
        child: Center(
          child: Icon(
            Icons.flag_outlined,
            size: 20.sp,
            color: AppCustomColor.textQuaternary,
          ),
        ),
      ),
    );
  }

  void _openReportIssueSheet(BuildContext context, KeypointEntity keypoint) {
    final lessonId = context.read<CourseLessonCubit>().state.selectedLesson.id;
    ReportIssueSheet.show(
      context,
      lessonId: lessonId,
      keypointId: keypoint.id,
      keypointTitle: keypoint.title.text,
      keypointImage: keypoint.image,
    );
  }

  Future<void> _handleOpenAudioSpeedSheet() async {
    final trackingData = KeypointTrackingData.fromContext();
    if (trackingData != null) {
      AppService.instance.appTrackingService.trackKeypointAudioSpeedOpen(trackingData);
    }
    await _openSpeedSheet();
  }

  void _handleAnswerChecked(bool isCorrect) {
    debugPrint('Answer is correct: $isCorrect');
    final lessonState = context.read<LessonCubit>().state;
    if (lessonState.currentLearningItem.type != LearningItemType.exercise) return;
    context.read<LessonCubit>().markPendingAdvance();
  }

  void _showLessonNavigationPopupIfNeeded() {
    final userCubit = context.read<UserCubit>();
    _controller.showLessonNavigationPopupIfNeeded(
      isFirstTime: userCubit.state.isFirstTimeLessonNavigationGuide,
      onMarkSeen: () => userCubit.setIsFirstTimeLessonNavigationGuide(false),
      onShowPopup: () => LessonNavigationPopup.show(context),
    );
  }

  Widget _buildActiveBody(BuildContext context, LessonState state) {
    if (state.pageData.items.isEmpty) return const SizedBox.shrink();

    switch (state.currentLearningItem.type) {
      case LearningItemType.exercise || LearningItemType.roleplay:
        final question = context.select((ExerciseCubit bloc) => bloc.state.currentQuestion);
        return _bodyFactory.buildExerciseBody(question);
      case LearningItemType.theory:
        return TheoryLessonBody(onAnswerChecked: _handleAnswerChecked);
      case LearningItemType.video:
      case LearningItemType.unknown:
        return const SizedBox.shrink();
    }
  }

  void _trackCurrentLearningItemScroll() {
    _trackingDelegate.trackCurrentLearningItemScroll(
      lessonState: context.read<LessonCubit>().state,
      shouldTrackScroll: _controller.shouldTrackScroll,
    );
  }

  void _trackAudioExitIfNeeded() {
    if (!_selectedMode.isAudio) return;

    final trackingData = KeypointTrackingData.fromContext();
    if (trackingData == null) return;

    AppService.instance.appTrackingService.trackKeypointAudioExitClick(
      trackingData,
      audioPosition: _lessonAudioCubit.state.positionSeconds,
    );
  }
}
