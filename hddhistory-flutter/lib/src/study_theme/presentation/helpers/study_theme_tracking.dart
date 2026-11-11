part of '../../study_theme.dart';

/// Safe fire-and-forget tracking for the Change-Background (study theme) flow.
/// Mirrors [HomeTracking.track]: never throws and never blocks the UI, so a
/// tracking failure can never break a tap handler.
class StudyThemeTracking {
  const StudyThemeTracking._();

  static void track(String eventName, {Map<String, dynamic>? parameters}) {
    final eventParameters = <String, dynamic>{...?parameters}..removeWhere((_, value) => value == null);
    try {
      final trackingService = AppService.instance.appTrackingService;
      unawaited(
        trackingService.trackEvent(eventName, parameters: eventParameters.isEmpty ? null : eventParameters).catchError((_) {}),
      );
    } catch (_) {
      return;
    }
  }
}
