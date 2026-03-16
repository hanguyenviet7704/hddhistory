part of '../../services.dart';

class NotificationForegroundPolicy {
  const NotificationForegroundPolicy();

  bool shouldRender({
    required NotificationPayload payload,
    required NotificationCoreConfig config,
  }) {
    if (!config.enableLocal || !payload.hasVisibleContent) {
      return false;
    }

    final override = config.shouldRenderForegroundNotification;
    if (override != null) {
      return override(payload);
    }

    final rawDecision = payload.raw[NotificationConstants.foregroundRenderKey]?.toString().toLowerCase();
    if (rawDecision == 'true' || rawDecision == '1') {
      return true;
    }
    if (rawDecision == 'false' || rawDecision == '0') {
      return false;
    }

    return true;
  }
}
