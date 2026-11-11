part of '../../home.dart';

/// Safe fire-and-forget tracking for Home-tab tap events. Mirrors
/// [OnboardV2Tracking.track]: never throws and never blocks the UI (unawaited
/// + swallowed errors), so a tracking failure can never break a tap handler.
class HomeTracking {
  const HomeTracking._();

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
