part of '../../services.dart';

enum NotificationPermissionStatus { authorized, denied, notDetermined, provisional, unsupported }

extension NotificationPermissionStatusX on NotificationPermissionStatus {
  bool get isAuthorized => this == NotificationPermissionStatus.authorized || this == NotificationPermissionStatus.provisional;

  bool get canRequest => this == NotificationPermissionStatus.notDetermined;
}

@immutable
class NotificationPermissionState {
  const NotificationPermissionState({
    required this.status,
    required this.systemNotificationsEnabled,
    required this.localNotificationsEnabled,
    required this.pushNotificationsEnabled,
    this.canRequest = false,
    this.canOpenSettings = true,
  });

  final NotificationPermissionStatus status;
  final bool systemNotificationsEnabled;
  final bool localNotificationsEnabled;
  final bool pushNotificationsEnabled;
  final bool canRequest;
  final bool canOpenSettings;

  bool get isAuthorized => status.isAuthorized;
}

enum NotificationPayloadSource { remote, local }

enum NotificationInteractionType { foregroundReceived, openedApp, coldStart, localAction }

@immutable
class NotificationPayload {
  const NotificationPayload({
    this.source = NotificationPayloadSource.remote,
    this.raw = const <String, dynamic>{},
    this.sourceId,
    this.type,
    this.title = '',
    this.body = '',
    this.deeplink,
    this.entityId,
    this.imageUrl,
  });

  final NotificationPayloadSource source;
  final Map<String, dynamic> raw;
  final String? sourceId;
  final String? type;
  final String title;
  final String body;
  final String? deeplink;
  final String? entityId;
  final String? imageUrl;

  bool get hasVisibleContent => title.trim().isNotEmpty || body.trim().isNotEmpty || (imageUrl?.trim().isNotEmpty ?? false);

  NotificationPayload copyWith({
    NotificationPayloadSource? source,
    Map<String, dynamic>? raw,
    String? sourceId,
    String? type,
    String? title,
    String? body,
    String? deeplink,
    String? entityId,
    String? imageUrl,
  }) {
    return NotificationPayload(
      source: source ?? this.source,
      raw: raw ?? this.raw,
      sourceId: sourceId ?? this.sourceId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      deeplink: deeplink ?? this.deeplink,
      entityId: entityId ?? this.entityId,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

@immutable
class NotificationInteraction {
  const NotificationInteraction({
    required this.type,
    required this.payload,
    required this.occurredAt,
    this.actionKey,
    this.inputText,
  });

  final NotificationInteractionType type;
  final NotificationPayload payload;
  final DateTime occurredAt;
  final String? actionKey;
  final String? inputText;
}

@immutable
class NotificationRequest {
  const NotificationRequest({
    this.id,
    this.title = '',
    this.body = '',
    this.summary,
    this.imageUrl,
    this.payload = const <String, String>{},
  });

  final int? id;
  final String title;
  final String body;
  final String? summary;
  final String? imageUrl;
  final Map<String, String> payload;
}

@immutable
class NotificationScheduleRequest {
  const NotificationScheduleRequest({
    required this.notification,
    this.scheduledAt,
    this.interval,
    this.repeats = false,
    this.preciseAlarm = true,
  }) : assert(scheduledAt != null || interval != null, 'Either scheduledAt or interval must be provided.'),
       assert(scheduledAt == null || interval == null, 'Use either scheduledAt or interval, not both.');

  final NotificationRequest notification;
  final DateTime? scheduledAt;
  final Duration? interval;
  final bool repeats;
  final bool preciseAlarm;
}

@immutable
class NotificationTokenState {
  const NotificationTokenState({
    this.token = '',
    this.updatedAt,
    this.isFromRefresh = false,
  });

  final String token;
  final DateTime? updatedAt;
  final bool isFromRefresh;

  bool get hasToken => token.trim().isNotEmpty;
}

@immutable
class TransportRemoteMessage {
  const TransportRemoteMessage({
    required this.data,
    this.messageId,
    this.title,
    this.body,
    this.hasNotificationPayload = false,
  });

  final Map<String, dynamic> data;
  final String? messageId;
  final String? title;
  final String? body;
  final bool hasNotificationPayload;
}

@immutable
class TransportLocalAction {
  const TransportLocalAction({
    required this.id,
    required this.payload,
    required this.performedAt,
    this.title,
    this.body,
    this.actionKey,
    this.inputText,
    this.fromBackground = false,
    this.fromTerminated = false,
  });

  final int id;
  final Map<String, String> payload;
  final DateTime performedAt;
  final String? title;
  final String? body;
  final String? actionKey;
  final String? inputText;
  final bool fromBackground;
  final bool fromTerminated;
}

@immutable
class NotificationChannelConfig {
  const NotificationChannelConfig({
    required this.channelKey,
    required this.channelGroupKey,
    required this.channelName,
    required this.channelDescription,
    required this.channelGroupName,
  });

  final String channelKey;
  final String channelGroupKey;
  final String channelName;
  final String channelDescription;
  final String channelGroupName;
}
