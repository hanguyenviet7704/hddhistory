part of '../../video_lesson.dart';

extension _VideoLessonPageOverlayActions on _VideoLessonPageState {
  Future<void> _handleOpenNotes(VideoLessonState state) async {
    if (state.hasPendingSkippedQuestions) {
      context.showDSnackBar(
        message: context.l10n.videoLesson.continueWatchingButton,
        type: MessageType.info,
      );
      return;
    }

    final wasPlaying = await _pauseVideoForUtilityAction();
    final opened = _cubit.openNotes(wasPlayingBeforeOverlay: wasPlaying);
    if (opened) {
      _cancelControlsAutoHide();
    } else if (wasPlaying) {
      await _resumeVideoAfterUtilityAction();
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

    final wasPlaying = await _pauseVideoForUtilityAction();
    final opened = _cubit.openSummary(wasPlayingBeforeOverlay: wasPlaying);
    if (opened) {
      _cancelControlsAutoHide();
    } else if (wasPlaying) {
      await _resumeVideoAfterUtilityAction();
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
    await _pauseVideoForUtilityAction();
    if (!mounted) return;

    final trackingData = _trackingData(state);
    if (trackingData != null) {
      AppService.instance.appTrackingService.trackVideoLessonShareClick(
        trackingData,
        nodeId: state.nodeId,
      );
    }

    final cacheService = AppDI.injector.get<ICacheService>(
      instanceName: DIKey.cacheService,
    );
    final mediaService = AppDI.injector.get<IMediaService>();
    final sharePositionOrigin = mediaService.getSharePositionOrigin(context);
    final thumbnailUrl = videoLessonNormalizedShareThumbnailUrl(
      state.lesson.video.thumbnail,
    );

    if (thumbnailUrl.isNotEmpty) {
      try {
        final cachedThumbnailFile = await cacheService.getCachedImageIfAvailable(
          thumbnailUrl,
        );
        if (cachedThumbnailFile != null) {
          await mediaService.shareImageFile(
            cachedThumbnailFile,
            shareText: _VideoLessonPageState._shareText,
            sharePositionOrigin: sharePositionOrigin,
          );
          return;
        }

        unawaited(cacheService.preloadImages([thumbnailUrl]));
      } catch (_) {
        // Fallback to text-only share.
      }
    }

    await SharePlus.instance.share(
      ShareParams(
        text: _VideoLessonPageState._shareText,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  Future<bool> _pauseVideoForUtilityAction() async {
    final controller = _controller;
    final wasPlaying = controller?.value.isPlaying ?? false;
    if (!wasPlaying) return false;

    _cancelControlsAutoHide();
    await controller?.pause();
    _cubit.setPlaybackState(isPlaying: false, controlsVisible: true);
    return true;
  }

  Future<void> _resumeVideoAfterUtilityAction() async {
    await _controller?.play();
    _cubit.setPlaybackState(isPlaying: true, controlsVisible: false);
    _scheduleControlsAutoHide();
  }

  Future<void> _handleExit(VideoLessonState state) async {
    if (_hasTrackedExit || !mounted) return;

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
}
