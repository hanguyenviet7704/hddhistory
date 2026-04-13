part of '../../video_lesson.dart';

extension _VideoLessonPageBuilders on _VideoLessonPageState {
  void _initializeLesson() {
    _cubit.initialize(
      courseId: widget.courseId,
      nodeId: widget.nodeId,
      lessonId: widget.lessonId,
    );
  }

  CourseLessonTrackingData? _trackingData(VideoLessonState state) {
    if (state.lesson.id.isEmpty) return null;
    return CourseLessonTrackingData.fromLesson(context, state.lesson);
  }

  Iterable<BlocListener<VideoLessonCubit, VideoLessonState>> _buildBlocListeners() {
    return [
      BlocListener<VideoLessonCubit, VideoLessonState>(
        listenWhen: (previous, current) => previous.lesson.video.url != current.lesson.video.url && current.hasVideo,
        listener: (context, state) => _initializeController(state.lesson.video.url),
      ),
      BlocListener<VideoLessonCubit, VideoLessonState>(
        listenWhen: (previous, current) => videoLessonShouldPreloadShareThumbnail(
          previous: previous,
          current: current,
        ),
        listener: (context, state) => _preloadShareThumbnail(state.lesson.video.thumbnail),
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
    ];
  }

  Widget _buildPageBody() {
    return BlocBuilder<VideoLessonCubit, VideoLessonState>(
      builder: (context, state) {
        switch (state.loadStatus) {
          case VideoLessonLoadStatus.initial:
          case VideoLessonLoadStatus.loading:
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          case VideoLessonLoadStatus.failure:
            return _VideoLessonStatusView(
              message: state.errorMessage ?? context.l10n.common.errorOopsSomethingWentWrongWhileLoading,
              onRetry: _initializeLesson,
              onExit: () => _handleExit(state),
            );
          case VideoLessonLoadStatus.unavailable:
            return _VideoLessonStatusView(
              message: context.l10n.videoLesson.unavailableMessage,
              onRetry: null,
              onExit: () => _handleExit(state),
            );
          case VideoLessonLoadStatus.success:
            return _buildReadyStateView(state);
        }
      },
    );
  }

  Widget _buildReadyStateView(VideoLessonState state) {
    return ValueListenableBuilder<_VideoLessonPagePlayerViewState>(
      valueListenable: _playerViewStateNotifier,
      builder: (context, playerViewState, _) => _VideoLessonReadyView(
        controller: playerViewState.controller,
        isInitializingController: playerViewState.isInitializingController,
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
        onSummaryScroll: _handleSummaryScroll,
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
        onComplete: () => _handleComplete(state),
      ),
    );
  }

  void _handleSummaryScroll() {
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
  }

  void _preloadShareThumbnail(String rawUrl) {
    final thumbnailUrl = videoLessonNormalizedShareThumbnailUrl(rawUrl);
    if (thumbnailUrl.isEmpty) return;
    unawaited(
      AppDI.injector
          .get<ICacheService>(
            instanceName: DIKey.cacheService,
          )
          .preloadImages([thumbnailUrl]),
    );
  }

  void _handleComplete(VideoLessonState state) {
    final trackingData = _trackingData(state);
    if (trackingData != null) {
      AppService.instance.appTrackingService.trackVideoLessonMarkCompleteClick(
        trackingData,
        nodeId: state.nodeId,
      );
    }
    _cubit.completeLesson();
  }
}
