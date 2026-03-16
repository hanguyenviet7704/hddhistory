part of '../services.dart';

typedef NotificationPayloadDecoder = NotificationPayload Function(Map<String, dynamic> raw);
typedef NotificationTokenChangedCallback = FutureOr<void> Function(NotificationTokenState state);
typedef NotificationInteractionCallback = FutureOr<void> Function(NotificationInteraction interaction);
typedef NotificationForegroundRenderPredicate = bool Function(NotificationPayload payload);

@immutable
class NotificationCoreConfig {
  const NotificationCoreConfig({
    this.enablePush = true,
    this.enableLocal = true,
    this.autoRequestPermissionOnInit = false,
    this.payloadDecoder,
    this.onTokenChanged,
    this.onInteraction,
    this.shouldRenderForegroundNotification,
  });

  final bool enablePush;
  final bool enableLocal;
  final bool autoRequestPermissionOnInit;
  final NotificationPayloadDecoder? payloadDecoder;
  final NotificationTokenChangedCallback? onTokenChanged;
  final NotificationInteractionCallback? onInteraction;
  final NotificationForegroundRenderPredicate? shouldRenderForegroundNotification;
}
