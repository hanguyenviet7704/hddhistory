part of '../../video_lesson.dart';

extension _VideoLessonPageControllerActions on _VideoLessonPageState {
  Future<void> _initializeController(String url) async {
    if (url.isEmpty || _controllerUrl == url) return;
    _disposeController();
    _controllerUrl = url;
    _isInitializingController = true;
    _refreshUi();

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
    _refreshUi();
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

    if (previousState.isPlaying &&
        _cubit.processPlaybackAdvance(
          fromSecond: previousPosition,
          toSecond: value.position.inSeconds,
        )) {
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
    if (!_cubit.state.isPlaying || !_cubit.state.controlsVisible || _cubit.state.hasBlockingOverlay) {
      return;
    }
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
    if (controller == null || !controller.value.isInitialized || state.isEndVisible) {
      return;
    }

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
}
