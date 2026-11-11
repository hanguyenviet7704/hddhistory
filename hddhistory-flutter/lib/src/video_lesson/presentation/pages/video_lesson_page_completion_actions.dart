part of '../../video_lesson.dart';

extension _VideoLessonPageCompletionActions on _VideoLessonPageState {
  void _handleComplete(VideoLessonState state) {
    if (videoLessonShouldDisableCompletionSubmit(state.completionStatus)) {
      return;
    }

    final trackingData = _trackingData(state);
    if (trackingData != null) {
      AppService.instance.appTrackingService.trackVideoLessonMarkCompleteClick(
        trackingData,
        nodeId: state.nodeId,
      );
    }
    _cubit.completeLesson();
  }

  Future<void> _handleCompletionSuccessAfterProgress(VideoLessonState state) async {
    if (_isHandlingCompletionSuccess || _hasTrackedExit || !mounted) return;
    _isHandlingCompletionSuccess = true;

    // The streak popup used to be raised here, on keypoint completion. It now
    // fires on time spent in the app instead ([StreakPopupScheduler]), so this
    // path only has to get out of the way of whatever modal is already up.
    if (!mounted || _hasTrackedExit) return;
    if (LearningStreakModalGuard.hasBlockingModal(context)) {
      await _waitForCurrentRouteBeforeCompletionExit();
      if (!mounted || _hasTrackedExit) return;
    }

    await _handleExit(state);
  }

  Future<void> _waitForCurrentRouteBeforeCompletionExit() async {
    while (mounted && !_hasTrackedExit && LearningStreakModalGuard.hasBlockingModal(context)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }
}
