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
  // Source for the next keypoint_read_scr_view: 'keypoint_intro' on entry,
  // flipped to 'mode_switch' the moment the user switches into read mode.
  String _readViewSource = 'keypoint_intro';

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
      // Assert this page's (non-primary) route name so the shell's floating nav
      // pill stays hidden over the lesson. Otherwise the first-time navigation
      // popup (and any other overlay) shown below writes the UNDERLYING primary
      // route name (courseRoadmap) on dismissal, un-hiding the nav over the CTA.
      _ensureLessonRouteName();
      await _syncAudioKeypoint(context.read<CourseLessonCubit>().state.resolvedCurrentKeypoint);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Keeps the floating nav pill hidden while the lesson is shown. The pill is
  /// gated on [PageStateX.isPrimaryRoute]; overlays dismissed above this page
  /// make the route observer write the underlying (primary) route name, so we
  /// re-assert this page's name whenever it's flipped back — but only while the
  /// lesson is still the current route (mirrors keypoint_complete_page).
  void _ensureLessonRouteName() {
    if (!mounted) return;
    AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.lesson);
  }

  @override
  Widget build(BuildContext context) {
    final currentKeypoint = context.select((CourseLessonCubit cubit) => cubit.state.resolvedCurrentKeypoint);

    return MultiBlocListener(
      listeners: [
        // Any overlay dismissed above this page (nav guide, report sheet, exit
        // flow…) makes the route observer write the UNDERLYING route's name — a
        // primary one (courseRoadmap) — which un-hides the floating nav over the
        // lesson's CTA. As long as the lesson is still the current route, take
        // the name back (mirrors keypoint_complete_page).
        BlocListener<PageCubit, PageState>(
          bloc: AppDI.injector.get<PageCubit>(),
          listenWhen: (previous, current) => previous.currentRouteName != current.currentRouteName && current.isPrimaryRoute,
          listener: (context, state) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
              _ensureLessonRouteName();
            });
          },
        ),
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
          listener: (context, state) {
            _trackingDelegate.trackKeypointTheoryScrView(state, source: _readViewSource);
            _readViewSource = 'keypoint_intro';
          },
        ),
        BlocListener<ExerciseCubit, ExerciseState>(
          listenWhen: (previous, current) {
            return previous.currentQuestionIndex != current.currentQuestionIndex ||
                previous.currentLearningItem.id != current.currentLearningItem.id ||
                previous.currentQuestion.id != current.currentQuestion.id;
          },
          listener: (context, state) {
            _trackingDelegate.trackKeypointExerciseScrView(state, source: _readViewSource);
            _readViewSource = 'keypoint_intro';
          },
        ),
      ],
      child: BlocBuilder<LessonCubit, LessonState>(
        // This builder only renders: the timeline/active body (depends on
        // pageData + currentLearningItemIndex + currentLessonIndex), the
        // auto-scroll trigger (suppressNextAutoScroll), and the loading
        // overlay (status/errorMessage). Every other field is either pure
        // cubit-internal bookkeeping (hasPendingAdvance, subQuestions) or
        // already consumed by its own narrower BlocSelector elsewhere
        // (isBottomButtonVisible in lesson_layout.dart, isShowResultOverlay
        // in speaking_bottom_action.dart) or by a different page
        // (completionOrigin in keypoint_complete_page.dart) — those must NOT
        // trigger a rebuild here to avoid rebuilding the whole lesson
        // subtree on every keypoint advance/answer check/audio tick.
        buildWhen: (previous, current) {
          return previous.status != current.status ||
              previous.errorMessage != current.errorMessage ||
              previous.pageData != current.pageData ||
              previous.currentLearningItemIndex != current.currentLearningItemIndex ||
              previous.currentLessonIndex != current.currentLessonIndex ||
              previous.suppressNextAutoScroll != current.suppressNextAutoScroll;
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

          // Top-right overflow menu (grid icon): opens the mode-aware
          // KeypointSettingsSheet (Change theme + Report a problem always,
          // plus Text display / Speed + Background music depending on mode).
          // Shown in BOTH modes now (Listen mode no longer swaps it out for a
          // standalone speed pill — Speed lives in the sheet instead).
          final headerMenu = LessonHeaderMenu(
            mode: _selectedMode,
            onReportProblem: () => _openReportIssueSheet(context, currentKeypoint),
            onOpenSpeedSheet: _handleOpenAudioSpeedSheet,
          );

          if (!currentKeypoint.hasUsableAudio) {
            return LessonShellLayout(
              selectedMode: LessonEntryMode.read,
              onModeSelected: (_) {},
              onClose: () => LessonExitFlow.open(context, mode: 'read'),
              showModeToggle: false,
              readBody: readSurface,
              audioBody: const SizedBox.shrink(),
              bottom: bottomButton,
              trailing: headerMenu,
              isLoading: state.status == LessonStatus.loading,
            );
          }

          final selectedMode = _selectedMode;
          return LessonDualModeLayout(
            selectedMode: selectedMode,
            onModeSelected: _handleModeSelected,
            onClose: () => LessonExitFlow.open(
              context,
              mode: _selectedMode.isAudio ? 'listen' : 'read',
              onBeforePopup: () {
                context.read<LessonAudioCubit>().pauseForOverlay();
                return Future.value();
              },
            ),
            readBody: readSurface,
            audioBody: const LessonAudioSurface(),
            bottom: selectedMode.isRead ? bottomButton : null,
            trailing: headerMenu,
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
      _trackAudioShellViewIfNeeded('keypoint_intro');
      await _lessonAudioCubit.enterAudioMode();
    } else {
      // Read mode: warm the audio in the background so switching to "Nghe"
      // later finds it ready instead of waiting on the ~5s load spinner.
      unawaited(_lessonAudioCubit.preload());
    }
  }

  void _trackAudioShellViewIfNeeded(String source) {
    if (_hasTrackedAudioShellView) return;
    final trackingData = KeypointTrackingData.fromContext();
    if (trackingData == null) return;

    _hasTrackedAudioShellView = true;
    AppService.instance.appTrackingService.trackKeypointAudioScreenView(
      trackingData,
      mode: _selectedMode.routeValue,
      source: source,
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
    // The read scr_view that follows a switch into read mode is sourced
    // 'mode_switch' (reset to 'keypoint_intro' by the scr_view listener).
    if (nextMode.isRead) _readViewSource = 'mode_switch';

    if (trackingData != null) {
      AppService.instance.appTrackingService.trackKeypointAudioModeSwitch(
        trackingData,
        mode: nextMode.routeValue,
        entryPoint: 'in_route_switch',
        audioPosition: nextMode.isRead ? _lessonAudioCubit.state.positionSeconds : null,
      );
    }

    if (nextMode.isAudio) {
      _trackAudioShellViewIfNeeded('mode_switch');
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

  void _openReportIssueSheet(BuildContext context, KeypointEntity keypoint) {
    final lessonId = context.read<CourseLessonCubit>().state.selectedLesson.id;
    ReportIssueSheet.show(
      context,
      lessonId: lessonId,
      keypointId: keypoint.id,
      keypointTitle: keypoint.title.text,
      keypointImage: keypoint.image,
      mode: _selectedMode.isAudio ? 'listen' : 'read',
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
    isCorrect ? AppHaptic.success() : AppHaptic.error();
    context.read<LessonCubit>().markPendingAdvance();
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
}
