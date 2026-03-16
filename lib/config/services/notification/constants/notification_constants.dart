import '../models/notification_models.dart';

abstract final class NotificationConstants {
  static const String defaultTitle = 'You have a new notification';
  static const String defaultBody = 'Open the app to see more details.';

  static const String payloadTypeKey = 'type';
  static const String payloadTitleKey = 'title';
  static const String payloadBodyKey = 'body';
  static const String payloadDeeplinkKey = 'deeplink';
  static const String payloadDeepLinkKey = payloadDeeplinkKey;
  static const String payloadNavigateKey = 'navigate';
  static const String payloadEntityIdKey = 'entityId';
  static const String payloadImageUrlKey = 'imageUrl';
  static const String payloadSourceKey = 'source';
  static const String payloadMessageIdKey = 'messageId';
  static const String payloadNestedMessageKey = 'message';
  static const String foregroundRenderKey = 'renderForeground';

  static const NotificationChannelConfig defaultChannel = NotificationChannelConfig(
    channelKey: 'high_importance_channel',
    channelGroupKey: 'high_importance_channel_group',
    channelName: 'Basic notifications',
    channelDescription: 'Notification channel for notification core events',
    channelGroupName: 'General Notifications',
  );
}
