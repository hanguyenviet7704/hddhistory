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

  void _refreshUi() => setState(() {});

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
                },
              ),
              BlocListener<VideoLessonCubit, VideoLessonState>(
                listenWhen: (previous, current) => videoLessonShouldAutoExitOnCompletionSuccess(
                  previous: previous,
                  current: current,
                ),
                listener: (context, state) {
                  unawaited(_handleExit(state));
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
