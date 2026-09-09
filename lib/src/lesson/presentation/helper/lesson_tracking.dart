part of '../../lesson.dart';

/// Analytics for the tracking sheet's "new" tab (2026-08): the keypoint recap
/// and daily-quota locked cards, the complete-screen split, the practice hub
/// and the practice quiz.
///
/// Mirrors [HabitTracking]'s safe dispatch shape: every call is
/// fire-and-forget, wrapped in try/catch + `.catchError` + `unawaited`, so a
/// tracking failure can never break the reader flow it is attached to.
class LessonTracking {
  const LessonTracking._();

  static void track(String eventName, {Map<String, dynamic>? parameters}) {
    final eventParameters = <String, dynamic>{...?parameters}..removeWhere((_, value) => value == null);

    try {
      final trackingService = AppService.instance.appTrackingService;
      unawaited(trackingService.trackEvent(eventName, parameters: eventParameters).catchError((_) {}));
    } catch (_) {
      return;
    }
  }

  /// The identity block every keypoint-scoped event carries — the same shape
  /// the service's `_keypointParams` builds for the existing keypoint events.
  ///
  /// Null (imported lesson, no current keypoint) drops the event entirely,
  /// matching [LessonTrackingDelegate]'s convention: no event is better than
  /// one filed against the wrong course.
  static Map<String, dynamic>? keypointParams() {
    final trackingData = KeypointTrackingData.fromContext();
    if (trackingData == null) return null;
    return {
      'skill_id': trackingData.skillset.id,
      'skill_name': trackingData.skillset.trackingName,
      'course_id': trackingData.course.id,
      'course_name': trackingData.course.trackingName,
      'lesson_id': trackingData.lesson.id,
      'lesson_name': trackingData.lesson.trackingName,
      'keypoint_id': trackingData.keypoint.id,
      'keypoint_name': trackingData.keypoint.trackingName,
      // Nhánh A/B nội dung. Phải đóng dấu Ở ĐÂY NỮA: helper này là đường
      // tracking thứ hai, không đi qua `_keypointParams` của service — và
      // `keypoint_complete_skip` (tín hiệu âm của phễu A/B) chỉ bắn qua đây.
      ...ContentExperimentTracker.instance.paramsFor(trackingData.course.id),
    };
  }

  static void _trackWithKeypoint(String eventName, {Map<String, dynamic>? parameters}) {
    final params = keypointParams();
    if (params == null) return;
    track(eventName, parameters: {...params, ...?parameters});
  }

  //* Keypoint read mode — recap card + locked card
  static void readScrView({required String source, required String cardType}) {
    _trackWithKeypoint(TrackingKey.keypointReadScrView, parameters: {'source': source, 'card_type': cardType});
  }

  static void recapTap() => _trackWithKeypoint(TrackingKey.keypointRecapTap);

  static void lockedScrView() => _trackWithKeypoint(TrackingKey.keypointLockedScrView);

  static void lockedPremiumClick() => _trackWithKeypoint(TrackingKey.keypointLockedPremiumClick);

  //* Keypoint complete screen
  static void practiceClick() => _trackWithKeypoint(TrackingKey.keypointPracticeClick);

  static void completeExit() => _trackWithKeypoint(TrackingKey.keypointCompleteExit);

  static void completeSkip() => _trackWithKeypoint(TrackingKey.keypointCompleteSkip);

  //* Practice hub
  static void practiceHubScrView() => _trackWithKeypoint(TrackingKey.practiceHubScrView);

  static void practiceModeSelect({required String mode}) {
    _trackWithKeypoint(TrackingKey.practiceModeSelect, parameters: {'mode': mode});
  }

  static void practiceHubExit() => _trackWithKeypoint(TrackingKey.practiceHubExit);

  //* Practice quiz
  static void pracQuizScrView() => _trackWithKeypoint(TrackingKey.pracQuizScrView);

  static void pracQuizCheckClick({required String questionType, required bool isCorrect}) {
    _trackWithKeypoint(TrackingKey.pracQuizCheckClick, parameters: {'question_type': questionType, 'is_correct': isCorrect});
  }

  static void pracQuizCompleteScrView() => _trackWithKeypoint(TrackingKey.pracQuizCompleteScrView);

  static void pracQuizExit() => _trackWithKeypoint(TrackingKey.pracQuizExit);
}
