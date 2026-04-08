part of '../../video_lesson.dart';

class VideoLessonPage extends StatefulWidget {
  const VideoLessonPage({
    super.key,
    required this.courseId,
    required this.nodeId,
    required this.lessonId,
  });

  final String courseId;
  final String nodeId;
  final String lessonId;

  @override
  State<VideoLessonPage> createState() => _VideoLessonPageState();
}

class _VideoLessonPageState extends State<VideoLessonPage> {
  static const _shareText =
      'Found a gem on MeUp! 💎 I had so much fun watching this and learned a lot. '
      'Sharing the love in case you need some inspiration today! 🙌\n'
      'Android: https://play.google.com/store/apps/details?id=com.eup.meup\n'
      'IOS: https://apps.apple.com/us/app/meup-up-your-skills/id6755175330';

  VideoPlayerController? _controller;
  String _controllerUrl = '';
  bool _isInitializingController = false;
  bool _hasTrackedExit = false;
  bool _isSeeking = false;
  bool _resumePlaybackAfterSeek = false;
  Timer? _controlsAutoHideTimer;

  VideoLessonCubit get _cubit => context.read<VideoLessonCubit>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cubit.initialize(
        courseId: widget.courseId,
        nodeId: widget.nodeId,
        lessonId: widget.lessonId,
      );
    });
  }

  @override
  void dispose() {
    _controlsAutoHideTimer?.cancel();
    _disposeController();
    super.dispose();
  }

  CourseLessonTrackingData? _trackingData(VideoLessonState state) {
    if (state.lesson.id.isEmpty) return null;
    return CourseLessonTrackingData.fromLesson(context, state.lesson);
  }

  Future<void> _initializeController(String url) async {
    if (url.isEmpty || _controllerUrl == url) return;
    _disposeController();
    _controllerUrl = url;
    _isInitializingController = true;
    setState(() {});

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    controller.addListener(_handleControllerTick);

    try {
      await controller.initialize();
      await controller.setLooping(false);
    } catch (_) {
      controller.removeListener(_handleControllerTick);
      await controller.dispose();
      if (!mounted) return;
      _controllerUrl = '';
      _isInitializingController = false;
      _cubit.setLoadFailure(context.l10n.videoLesson.unavailableMessage);
      return;
    }

    if (!mounted) {
      await controller.dispose();
      return;
    }

    _controller = controller;
    _isInitializingController = false;
    _cubit.updatePlaybackProgress(
      position: controller.value.position,
      duration: controller.value.duration,
    );
    setState(() {});
  }

  void _disposeController() {
    final controller = _controller;
    _controllerUrl = '';
    if (controller == null) return;
    controller.removeListener(_handleControllerTick);
    controller.dispose();
    _controller = null;
  }

  void _handleControllerTick() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isSeeking) return;

    final value = controller.value;
    final previousState = _cubit.state;
    final previousPosition = previousState.positionSeconds;

    _cubit.updatePlaybackProgress(
      position: value.position,
      duration: value.duration,
    );

    if (previousState.isPlaying && _cubit.processPlaybackAdvance(fromSecond: previousPosition, toSecond: value.position.inSeconds)) {
      unawaited(controller.pause());
      _cancelControlsAutoHide();
    }

    if (value.isPlaying != _cubit.state.isPlaying) {
      _cubit.setPlaybackState(
        isPlaying: value.isPlaying,
        controlsVisible: value.isPlaying ? _cubit.state.controlsVisible : true,
      );
    }

    if (value.isPlaying) {
      _scheduleControlsAutoHide();
    }

    final reachedEnd = value.isCompleted || (value.duration > Duration.zero && value.position >= value.duration);
    if (reachedEnd && !_cubit.state.isEndVisible && !_cubit.state.isQuestionVisible && !_cubit.state.isQuestionResultVisible && !_cubit.state.hasPendingSkippedQuestions) {
      unawaited(controller.pause());
      _cubit.showEndOverlay();
      _cancelControlsAutoHide();
    }
  }

  void _cancelControlsAutoHide() {
    _controlsAutoHideTimer?.cancel();
    _controlsAutoHideTimer = null;
  }

  void _scheduleControlsAutoHide() {
    if (!_cubit.state.isPlaying || !_cubit.state.controlsVisible || _cubit.state.hasBlockingOverlay) return;
    _controlsAutoHideTimer?.cancel();
    _controlsAutoHideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (_cubit.state.isPlaying && !_cubit.state.hasBlockingOverlay) {
        _cubit.setControlsVisible(false);
      }
    });
  }

  Future<void> _handlePlayPause(VideoLessonState state) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || state.isEndVisible) return;

    final trackingData = _trackingData(state);
    if (controller.value.isPlaying) {
      await controller.pause();
      _cancelControlsAutoHide();
      if (trackingData != null) {
        AppService.instance.appTrackingService.trackVideoLessonPauseClick(
          trackingData,
          nodeId: state.nodeId,
        );
      }
      _cubit.setPlaybackState(isPlaying: false, controlsVisible: true);
      return;
    }

    if (_cubit.maybeTriggerZeroSecondQuestion()) {
      _cancelControlsAutoHide();
      return;
    }

    await controller.play();
    if (trackingData != null) {
      AppService.instance.appTrackingService.trackVideoLessonPlayClick(
        trackingData,
        nodeId: state.nodeId,
      );
    }
    _cubit.setPlaybackState(isPlaying: true, controlsVisible: false);
    _scheduleControlsAutoHide();
  }

  Future<void> _handleOpenNotes(VideoLessonState state) async {
    if (state.hasPendingSkippedQuestions) {
      context.showDSnackBar(
        message: context.l10n.videoLesson.continueWatchingButton,
        type: MessageType.info,
      );
      return;
    }

    final controller = _controller;
    final wasPlaying = controller?.value.isPlaying ?? false;
    if (wasPlaying) {
      await controller?.pause();
    }
    final opened = _cubit.openNotes(wasPlayingBeforeOverlay: wasPlaying);
    if (opened) {
      _cancelControlsAutoHide();
    } else if (wasPlaying) {
      await controller?.play();
    }
  }

  Future<void> _handleCloseNotes() async {
    final shouldResume = _cubit.state.wasPlayingBeforeOverlay;
    _cubit.closeNotes();
    if (shouldResume) {
      await _controller?.play();
      _cubit.setPlaybackState(isPlaying: true, controlsVisible: false);
      _scheduleControlsAutoHide();
      return;
    }
    _cubit.setPlaybackState(isPlaying: false, controlsVisible: true);
  }

  Future<void> _handleOpenSummary(VideoLessonState state) async {
    if (state.hasPendingSkippedQuestions) {
      context.showDSnackBar(
        message: context.l10n.videoLesson.continueWatchingButton,
        type: MessageType.info,
      );
      return;
    }

    final controller = _controller;
    final wasPlaying = controller?.value.isPlaying ?? false;
    if (wasPlaying) {
      await controller?.pause();
    }
    final opened = _cubit.openSummary(wasPlayingBeforeOverlay: wasPlaying);
    if (opened) {
      _cancelControlsAutoHide();
    } else if (wasPlaying) {
      await controller?.play();
    }
  }

  Future<void> _handleCloseSummary({required bool trackClose}) async {
    final state = _cubit.state;
    final trackingData = _trackingData(state);
    if (trackClose && trackingData != null) {
      AppService.instance.appTrackingService.trackVideoLessonSummaryClose(
        trackingData,
        nodeId: state.nodeId,
      );
    }

    final shouldResume = state.wasPlayingBeforeOverlay;
    _cubit.closeSummary();
    if (shouldResume) {
      await _controller?.play();
      _cubit.setPlaybackState(isPlaying: true, controlsVisible: false);
      _scheduleControlsAutoHide();
      return;
    }
    _cubit.setPlaybackState(isPlaying: false, controlsVisible: true);
  }

  Future<void> _handleShare(VideoLessonState state) async {
    final trackingData = _trackingData(state);
    if (trackingData != null) {
      AppService.instance.appTrackingService.trackVideoLessonShareClick(
        trackingData,
        nodeId: state.nodeId,
      );
    }

    final mediaService = AppDI.injector.get<IMediaService>();
    final sharePositionOrigin = mediaService.getSharePositionOrigin(context);
    final thumbnailUrl = state.lesson.video.thumbnail.trim();

    if (thumbnailUrl.isNotEmpty) {
      try {
        final response = await Dio().get<List<int>>(
          thumbnailUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        final bytes = Uint8List.fromList(response.data ?? const []);
        if (bytes.isNotEmpty) {
          await mediaService.shareImageBytes(
            bytes,
            shareText: _shareText,
            fileName: 'video_lesson_${state.lessonId}.png',
            sharePositionOrigin: sharePositionOrigin,
          );
          return;
        }
      } catch (_) {
        // Fallback to text-only share.
      }
    }

    await SharePlus.instance.share(
      ShareParams(
        text: _shareText,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  void _handleSurfaceTap() {
    _cubit.toggleControlsVisibility();
    if (_cubit.state.controlsVisible) {
      _scheduleControlsAutoHide();
    }
  }

  void _handleSeekStart(double value) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    _isSeeking = true;
    _resumePlaybackAfterSeek = controller.value.isPlaying;
    _cancelControlsAutoHide();
    if (_resumePlaybackAfterSeek) {
      unawaited(controller.pause());
    }
    _cubit.setPlaybackState(isPlaying: false, controlsVisible: true);
  }

  void _handleSeekChanged(double value) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final seconds = value.round().clamp(0, controller.value.duration.inSeconds);
    _cubit.updatePlaybackProgress(
      position: Duration(seconds: seconds),
      duration: controller.value.duration,
    );
  }

  Future<void> _handleSeekEnd(double value) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final currentState = _cubit.state;
    final fromSecond = controller.value.position.inSeconds;
    final toSecond = value.round().clamp(0, controller.value.duration.inSeconds);
    _isSeeking = false;

    if (fromSecond == toSecond) {
      if (_resumePlaybackAfterSeek) {
        await controller.play();
        _cubit.setPlaybackState(isPlaying: true, controlsVisible: false);
        _scheduleControlsAutoHide();
      }
      _resumePlaybackAfterSeek = false;
      return;
    }

    final trackingData = _trackingData(currentState);
    if (trackingData != null) {
      AppService.instance.appTrackingService.trackVideoLessonSeek(
        trackingData,
        nodeId: currentState.nodeId,
        seekFromSecond: fromSecond,
        seekToSecond: toSecond,
      );
    }

    await controller.seekTo(Duration(seconds: toSecond));
    _cubit.updatePlaybackProgress(
      position: Duration(seconds: toSecond),
      duration: controller.value.duration,
    );

    var openedOverlay = false;
    if (toSecond > fromSecond) {
      openedOverlay = _cubit.handleForwardSeek(
        fromSecond: fromSecond,
        toSecond: toSecond,
        wasPlayingBeforeSeek: _resumePlaybackAfterSeek,
      );
    } else {
      _cubit.handleBackwardSeek(
        targetSecond: toSecond,
        wasPlayingBeforeSeek: _resumePlaybackAfterSeek,
      );
    }

    if (!openedOverlay && _resumePlaybackAfterSeek && !_cubit.state.hasBlockingOverlay) {
      await controller.play();
      _cubit.setPlaybackState(isPlaying: true, controlsVisible: false);
      _scheduleControlsAutoHide();
    } else {
      _cubit.setPlaybackState(isPlaying: false, controlsVisible: true);
    }

    _resumePlaybackAfterSeek = false;
  }

  Future<void> _handleExit(VideoLessonState state) async {
    if (_hasTrackedExit) {
      if (mounted) context.pop();
      return;
    }

    final trackingData = _trackingData(state);
    if (trackingData != null) {
      AppService.instance.appTrackingService.trackVideoLessonExitClick(
        trackingData,
        nodeId: state.nodeId,
      );
    }

    _hasTrackedExit = true;
    _cubit.clearSessionStateForExit();
    if (mounted) context.pop();
  }

  Future<void> _handleDeleteNote(UserVideoLessonNoteEntity note) async {
    final didConfirm =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: AppText(
              context.l10n.videoLesson.deleteNoteTitle,
              style: AppStyle.textBold18.copyWith(color: AppCustomColor.textPrimary),
            ),
            content: AppText(
              context.l10n.videoLesson.deleteNoteMessage,
              style: AppStyle.text14.copyWith(
                color: AppCustomColor.textSecondary,
                height: 1.75,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => dialogContext.pop(false),
                child: AppText(
                  context.l10n.videoLesson.keepEditingButton,
                  style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () => dialogContext.pop(true),
                child: AppText(
                  context.l10n.videoLesson.deleteNoteButton,
                  style: AppStyle.text14.copyWith(color: AppCustomColor.errorRed),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!didConfirm) return;

    final trackingData = _trackingData(_cubit.state);
    if (trackingData != null) {
      AppService.instance.appTrackingService.trackVideoLessonNoteDeleteClick(
        trackingData,
        nodeId: _cubit.state.nodeId,
        noteId: note.id,
      );
    }

    await _cubit.deleteNote(note);
  }

  Future<void> _handleSaveNote() async {
    final state = _cubit.state;
    final trackingData = _trackingData(state);
    final editingNote = state.editingNote;

    if (trackingData != null) {
      AppService.instance.appTrackingService.trackVideoLessonNoteSaveClick(
        trackingData,
        nodeId: state.nodeId,
        noteMode: editingNote == null ? 'create' : 'edit',
        noteId: editingNote?.id,
        atSecond: editingNote?.atSecond ?? state.positionSeconds,
      );
    }

    await _cubit.saveNote();
  }

  void _handleOpenCreateNote() {
    final state = _cubit.state;
    final trackingData = _trackingData(state);
    if (trackingData != null) {
      AppService.instance.appTrackingService.trackVideoLessonAddNoteClick(
        trackingData,
        nodeId: state.nodeId,
        noteMode: 'create',
        atSecond: state.positionSeconds,
      );
    }
    _cubit.openCreateNote();
  }

  void _handleOpenEditNote(UserVideoLessonNoteEntity note) {
    final trackingData = _trackingData(_cubit.state);
    if (trackingData != null) {
      AppService.instance.appTrackingService.trackVideoLessonNoteEditClick(
        trackingData,
        nodeId: _cubit.state.nodeId,
        noteId: note.id,
        noteMode: 'edit',
      );
    }
    _cubit.openEditNote(note);
  }

  void _handleSubmitQuestion() {
    final state = _cubit.state;
    final prompt = state.currentQuestionPrompt;
    if (prompt == null) return;
    final trackingData = _trackingData(state);
    if (trackingData != null) {
      final previewResult = state.currentQuestionIsSupported
          ? resolveChoiceCheckResult(
              isMultipleChoice: state.currentQuestionIsMultipleChoice,
              isNoCorrectSingleChoice: state.currentQuestionIsNoCorrectSingleChoice,
              selectedAnswerIndex: state.currentSelectedAnswerIndex,
              selectedAnswersIndices: state.currentSelectedAnswerIndices,
              correctOptionsIndices: _previewCorrectIndices(state),
            )
          : true;

      AppService.instance.appTrackingService.trackVideoLessonQuizCheck(
        trackingData,
        nodeId: state.nodeId,
        questionId: prompt.question.id.toString(),
        atSecond: prompt.atSecond,
        isCorrect: previewResult,
      );
    }
    _cubit.submitCurrentQuestion();
  }

  Future<void> _handleContinueAfterQuestion() async {
    final state = _cubit.state;
    final result = state.currentQuestionResult;
    final trackingData = _trackingData(state);
    if (trackingData != null && result != null) {
      AppService.instance.appTrackingService.trackVideoLessonQuizContinue(
        trackingData,
        nodeId: state.nodeId,
        questionId: result.questionId.toString(),
        atSecond: result.atSecond,
        isCorrect: result.isCorrect,
      );
    }

    final shouldResume = _cubit.continueAfterQuestion();
    if (shouldResume) {
      await _controller?.play();
      _cubit.setPlaybackState(isPlaying: true, controlsVisible: false);
      _scheduleControlsAutoHide();
    }
  }

  Set<int> _previewCorrectIndices(VideoLessonState state) {
    final question = state.currentQuestion;
    if (question == null) return const {};
    final options = questionRuntimeOptions(question);
    final indices = <int>{};
    for (int i = 0; i < options.length; i++) {
      if (options[i].isCorrect) indices.add(i);
    }
    if (state.currentQuestionIsNoCorrectSingleChoice && state.currentSelectedAnswerIndex >= 0) {
      return {state.currentSelectedAnswerIndex};
    }
    return indices;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop || _hasTrackedExit) return;
          final state = _cubit.state;
          final trackingData = _trackingData(state);
          if (trackingData != null) {
            AppService.instance.appTrackingService.trackVideoLessonExitClick(
              trackingData,
              nodeId: state.nodeId,
            );
          }
          _hasTrackedExit = true;
          _cubit.clearSessionStateForExit();
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF0D121C),
          body: MultiBlocListener(
            listeners: [
              BlocListener<VideoLessonCubit, VideoLessonState>(
                listenWhen: (previous, current) => previous.lesson.video.url != current.lesson.video.url && current.hasVideo,
                listener: (context, state) => _initializeController(state.lesson.video.url),
              ),
              BlocListener<VideoLessonCubit, VideoLessonState>(
                listener: (context, state) {
                  final trackingData = _trackingData(state);
                  if (trackingData != null && state.isReady && !state.screenViewTracked) {
                    AppService.instance.appTrackingService.trackVideoLessonScrView(
                      trackingData,
                      nodeId: state.nodeId,
                    );
                    _cubit.markScreenViewTracked();
                  }

                  if (trackingData != null && state.isNotesVisible && !state.notesViewTracked) {
                    AppService.instance.appTrackingService.trackVideoLessonNotesView(
                      trackingData,
                      nodeId: state.nodeId,
                    );
                    _cubit.markNotesViewTracked();
                  }

                  if (trackingData != null && state.isSummaryVisible && !state.summaryViewTracked) {
                    AppService.instance.appTrackingService.trackVideoLessonSummaryView(
                      trackingData,
                      nodeId: state.nodeId,
                    );
                    _cubit.markSummaryViewTracked();
                  }

                  if (trackingData != null && state.isQuestionVisible && state.currentQuestionPrompt != null && !state.questionViewTracked) {
                    AppService.instance.appTrackingService.trackVideoLessonQuizView(
                      trackingData,
                      nodeId: state.nodeId,
                      questionId: state.currentQuestionPrompt!.question.id.toString(),
                      atSecond: state.currentQuestionPrompt!.atSecond,
                    );
                    _cubit.markQuestionViewTracked();
                  }

                  if (trackingData != null && state.isQuestionResultVisible && state.currentQuestionResult != null && !state.questionResultViewTracked) {
                    AppService.instance.appTrackingService.trackVideoLessonQuizResultView(
                      trackingData,
                      nodeId: state.nodeId,
                      questionId: state.currentQuestionResult!.questionId.toString(),
                      atSecond: state.currentQuestionResult!.atSecond,
                      isCorrect: state.currentQuestionResult!.isCorrect,
                    );
                    _cubit.markQuestionResultViewTracked();
                  }

                  if (trackingData != null && state.isEndVisible && !state.endViewTracked) {
                    AppService.instance.appTrackingService.trackVideoLessonCompleteView(
                      trackingData,
                      nodeId: state.nodeId,
                    );
                    _cubit.markEndViewTracked();
                  }

                  if (state.hasBlockingOverlay) {
                    _cancelControlsAutoHide();
                  }

                  if (state.completionStatus == VideoLessonCompletionStatus.success && context.mounted) {
                    unawaited(_handleExit(state));
                  }
                },
              ),
            ],
            child: BlocBuilder<VideoLessonCubit, VideoLessonState>(
              builder: (context, state) {
                switch (state.loadStatus) {
                  case VideoLessonLoadStatus.initial:
                  case VideoLessonLoadStatus.loading:
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  case VideoLessonLoadStatus.failure:
                    return _VideoLessonStatusView(
                      message: state.errorMessage ?? context.l10n.common.errorOopsSomethingWentWrongWhileLoading,
                      onRetry: () => _cubit.initialize(
                        courseId: widget.courseId,
                        nodeId: widget.nodeId,
                        lessonId: widget.lessonId,
                      ),
                      onExit: () => _handleExit(state),
                    );
                  case VideoLessonLoadStatus.unavailable:
                    return _VideoLessonStatusView(
                      message: context.l10n.videoLesson.unavailableMessage,
                      onRetry: null,
                      onExit: () => _handleExit(state),
                    );
                  case VideoLessonLoadStatus.success:
                    return _VideoLessonReadyView(
                      controller: _controller,
                      isInitializingController: _isInitializingController,
                      state: state,
                      onClose: () => _handleExit(state),
                      onPlayPause: () => _handlePlayPause(state),
                      onSurfaceTap: _handleSurfaceTap,
                      onNotesTap: () => _handleOpenNotes(state),
                      onSummaryTap: () => _handleOpenSummary(state),
                      onShareTap: () => _handleShare(state),
                      onSeekStart: _handleSeekStart,
                      onSeekChanged: _handleSeekChanged,
                      onSeekEnd: _handleSeekEnd,
                      onCloseNotes: _handleCloseNotes,
                      onCloseSummary: () => _handleCloseSummary(trackClose: true),
                      onSummaryScroll: () {
                        final currentState = _cubit.state;
                        if (currentState.summaryScrollTracked) return;
                        final trackingData = _trackingData(currentState);
                        if (trackingData != null) {
                          AppService.instance.appTrackingService.trackVideoLessonSummaryScroll(
                            trackingData,
                            nodeId: currentState.nodeId,
                          );
                        }
                        _cubit.markSummaryScrollTracked();
                      },
                      onRetryNotes: () => _cubit.loadNotes(),
                      onLoadMoreNotes: _cubit.loadMoreNotes,
                      onAddNote: _handleOpenCreateNote,
                      onBackFromNoteEditor: _cubit.backToNotesList,
                      onSaveNote: _handleSaveNote,
                      onDraftChanged: _cubit.updateNoteDraft,
                      onEditNote: _handleOpenEditNote,
                      onDeleteNote: _handleDeleteNote,
                      onQuestionAnswerTap: _cubit.selectCurrentQuestionAnswer,
                      onSubmitQuestion: _handleSubmitQuestion,
                      onContinueAfterQuestion: _handleContinueAfterQuestion,
                      onComplete: () {
                        final trackingData = _trackingData(state);
                        if (trackingData != null) {
                          AppService.instance.appTrackingService.trackVideoLessonMarkCompleteClick(
                            trackingData,
                            nodeId: state.nodeId,
                          );
                        }
                        _cubit.completeLesson();
                      },
                    );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoLessonReadyView extends StatelessWidget {
  const _VideoLessonReadyView({
    required this.controller,
    required this.isInitializingController,
    required this.state,
    required this.onClose,
    required this.onPlayPause,
    required this.onSurfaceTap,
    required this.onNotesTap,
    required this.onSummaryTap,
    required this.onShareTap,
    required this.onSeekStart,
    required this.onSeekChanged,
    required this.onSeekEnd,
    required this.onCloseNotes,
    required this.onCloseSummary,
    required this.onSummaryScroll,
    required this.onRetryNotes,
    required this.onLoadMoreNotes,
    required this.onAddNote,
    required this.onBackFromNoteEditor,
    required this.onSaveNote,
    required this.onDraftChanged,
    required this.onEditNote,
    required this.onDeleteNote,
    required this.onQuestionAnswerTap,
    required this.onSubmitQuestion,
    required this.onContinueAfterQuestion,
    required this.onComplete,
  });

  final VideoPlayerController? controller;
  final bool isInitializingController;
  final VideoLessonState state;
  final VoidCallback onClose;
  final VoidCallback onPlayPause;
  final VoidCallback onSurfaceTap;
  final VoidCallback onNotesTap;
  final VoidCallback onSummaryTap;
  final VoidCallback onShareTap;
  final ValueChanged<double> onSeekStart;
  final ValueChanged<double> onSeekChanged;
  final ValueChanged<double> onSeekEnd;
  final VoidCallback onCloseNotes;
  final VoidCallback onCloseSummary;
  final VoidCallback onSummaryScroll;
  final VoidCallback onRetryNotes;
  final VoidCallback onLoadMoreNotes;
  final VoidCallback onAddNote;
  final VoidCallback onBackFromNoteEditor;
  final VoidCallback onSaveNote;
  final ValueChanged<String> onDraftChanged;
  final ValueChanged<UserVideoLessonNoteEntity> onEditNote;
  final ValueChanged<UserVideoLessonNoteEntity> onDeleteNote;
  final ValueChanged<int> onQuestionAnswerTap;
  final VoidCallback onSubmitQuestion;
  final VoidCallback onContinueAfterQuestion;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final showOverlayScrim = state.isNotesVisible || state.isSummaryVisible || state.isQuestionVisible || state.isQuestionResultVisible || state.isEndVisible;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: state.activeOverlay == VideoLessonOverlay.none ? onSurfaceTap : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFF0D121C)),
          Center(
            child: VideoLessonPlayerSurface(
              controller: controller,
              thumbnailUrl: state.lesson.video.thumbnail,
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isInitializingController)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          VideoLessonPlayerControls(
            state: state,
            onClose: onClose,
            onPlayPause: onPlayPause,
            onSummaryTap: onSummaryTap,
            onNotesTap: onNotesTap,
            onShareTap: onShareTap,
            onSeekStart: onSeekStart,
            onSeekChanged: onSeekChanged,
            onSeekEnd: onSeekEnd,
          ),
          if (showOverlayScrim)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: state.isEndVisible,
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: state.isNotesVisible || state.isSummaryVisible ? 4 : 17,
                    sigmaY: state.isNotesVisible || state.isSummaryVisible ? 4 : 17,
                  ),
                  child: Container(
                    color: Colors.black.withValues(alpha: state.isNotesVisible || state.isSummaryVisible ? 0.38 : 0.6),
                  ),
                ),
              ),
            ),
          if (state.isNotesVisible)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onCloseNotes,
                child: const SizedBox.expand(),
              ),
            ),
          if (state.isSummaryVisible)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onCloseSummary,
                child: const SizedBox.expand(),
              ),
            ),
          if (state.isNotesVisible)
            VideoLessonNotesSheet(
              state: state,
              onClose: onCloseNotes,
              onBack: onBackFromNoteEditor,
              onAddNote: onAddNote,
              onSave: onSaveNote,
              onRetry: onRetryNotes,
              onLoadMore: onLoadMoreNotes,
              onDraftChanged: onDraftChanged,
              onEditNote: onEditNote,
              onDeleteNote: onDeleteNote,
            ),
          if (state.isSummaryVisible)
            VideoLessonSummarySheet(
              summary: state.lesson.video.summary.text,
              onClose: onCloseSummary,
              onScroll: onSummaryScroll,
            ),
          if (state.isQuestionVisible)
            VideoLessonQuestionSheet(
              state: state,
              onAnswerTap: onQuestionAnswerTap,
              onSubmit: onSubmitQuestion,
            ),
          if (state.isQuestionResultVisible)
            VideoLessonQuestionResultSheet(
              state: state,
              onContinue: onContinueAfterQuestion,
            ),
          if (state.isEndVisible)
            VideoLessonEndSheet(
              lesson: state.lesson,
              isSubmitting: state.completionStatus == VideoLessonCompletionStatus.loading,
              errorMessage: state.completionErrorMessage,
              onSubmit: onComplete,
            ),
        ],
      ),
    );
  }
}

class _VideoLessonStatusView extends StatelessWidget {
  const _VideoLessonStatusView({
    required this.message,
    required this.onExit,
    this.onRetry,
  });

  final String message;
  final VoidCallback onExit;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText(
              message,
              maxLines: 8,
              textAlign: TextAlign.center,
              style: AppStyle.text16.copyWith(
                color: Colors.white,
                height: 1.6,
              ),
            ),
            24.verticalSpace,
            if (onRetry != null) ...[
              AppButton.primary(
                onPressed: onRetry,
                fullWidthBtn: true,
                height: 54.h,
                borderRadius: BorderRadius.circular(1000.r),
                child: AppText(
                  context.l10n.videoLesson.retryLoadButton,
                  style: AppStyle.textBold16.copyWith(color: Colors.white),
                ),
              ),
              12.verticalSpace,
            ],
            AppButton.secondary(
              onPressed: onExit,
              fullWidthBtn: true,
              height: 54.h,
              borderRadius: BorderRadius.circular(1000.r),
              child: AppText(
                context.l10n.videoLesson.backButton,
                style: AppStyle.textBold16.copyWith(
                  color: AppCustomColor.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
