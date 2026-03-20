part of '../../services.dart';

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

const int _notificationIdMinValue = -0x80000000;
const int _notificationIdMaxValue = 0x7FFFFFFF;
const int _notificationIdFallbackSeed = 0x811C9DC5;
const int _notificationIdFallbackPrime = 0x01000193;

int _normalizeNotificationId(int value) {
  if (value >= _notificationIdMinValue && value <= _notificationIdMaxValue) {
    return value;
  }

  return _stableNotificationId(value.toString());
}

int? _notificationIdFromString(String? value) {
  final normalizedValue = value?.trim();
  if (normalizedValue == null || normalizedValue.isEmpty) {
    return null;
  }

  final parsedValue = int.tryParse(normalizedValue);
  if (parsedValue != null) {
    return _normalizeNotificationId(parsedValue);
  }

  return _stableNotificationId(normalizedValue);
}

int _generateNotificationId() {
  final generatedValue = DateTime.now().microsecondsSinceEpoch & _notificationIdMaxValue;
  return generatedValue == 0 ? 1 : generatedValue;
}

int _stableNotificationId(String value) {
  var hash = _notificationIdFallbackSeed;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * _notificationIdFallbackPrime) & 0xFFFFFFFF;
  }

  final normalizedHash = hash & _notificationIdMaxValue;
  return normalizedHash == 0 ? 1 : normalizedHash;
}
