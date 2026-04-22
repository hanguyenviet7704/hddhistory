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

    LearningStreakCompletionGateResult gateResult;
    try {
      gateResult = await LearningStreakCompletionGate.run(context);
    } catch (_) {
      gateResult = LearningStreakCompletionGateResult.failedOpen;
    }

    if (!mounted || _hasTrackedExit) return;
    if (gateResult == LearningStreakCompletionGateResult.skippedBlockedModal) {
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
