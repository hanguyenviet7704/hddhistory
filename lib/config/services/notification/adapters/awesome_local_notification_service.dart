import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

import '../constants/notification_constants.dart';
import '../notification_core_config.dart';
import '../permissions/notification_permission_service.dart';

abstract interface class NotificationLocalNotifications implements NotificationLocalPermissionProvider {
  Future<void> initialize();
  Future<void> registerListeners();
  Stream<TransportLocalAction> get actionStream;
  Future<TransportLocalAction?> getInitialAction();
  Future<void> show(NotificationRequest request);
  Future<void> schedule(NotificationScheduleRequest request);
  Future<void> cancel(int id);
  Future<void> cancelSchedule(int id);
  Future<void> cancelAll();
  Future<void> cancelAllSchedules();
  Future<void> dispose();
}

abstract class AwesomeLocalNotificationsGateway {
  Future<bool> initialize(
    String? defaultIcon,
    List<NotificationChannel> channels, {
    List<NotificationChannelGroup>? channelGroups,
    bool debug,
  });
  Future<bool> setListeners({
    required ActionHandler onActionReceivedMethod,
    NotificationHandler? onNotificationCreatedMethod,
    NotificationHandler? onNotificationDisplayedMethod,
    ActionHandler? onDismissActionReceivedMethod,
  });
  Future<ReceivedAction?> getInitialNotificationAction({
    bool removeFromActionEvents = false,
  });
  Future<String> getLocalTimeZoneIdentifier();
  Future<bool> createNotification({
    required NotificationContent content,
    NotificationSchedule? schedule,
  });
  Future<void> cancel(int id);
  Future<void> cancelAll();
  Future<void> cancelSchedule(int id);
  Future<void> cancelAllSchedules();
  Future<bool> isNotificationAllowed();
  Future<bool> requestPermissionToSendNotifications();
}

class DefaultAwesomeLocalNotificationsGateway implements AwesomeLocalNotificationsGateway {
  final AwesomeNotifications _notifications = AwesomeNotifications();

  @override
  Future<void> cancel(int id) => _notifications.cancel(id);

  @override
  Future<void> cancelAll() => _notifications.cancelAll();

  @override
  Future<void> cancelAllSchedules() => _notifications.cancelAllSchedules();

  @override
  Future<void> cancelSchedule(int id) => _notifications.cancelSchedule(id);

  @override
  Future<bool> createNotification({
    required NotificationContent content,
    NotificationSchedule? schedule,
  }) {
    return _notifications.createNotification(
      content: content,
      schedule: schedule,
    );
  }

  @override
  Future<ReceivedAction?> getInitialNotificationAction({
    bool removeFromActionEvents = false,
  }) {
    return _notifications.getInitialNotificationAction(
      removeFromActionEvents: removeFromActionEvents,
    );
  }

  @override
  Future<String> getLocalTimeZoneIdentifier() => _notifications.getLocalTimeZoneIdentifier();

  @override
  Future<bool> initialize(
    String? defaultIcon,
    List<NotificationChannel> channels, {
    List<NotificationChannelGroup>? channelGroups,
    bool debug = false,
  }) {
    return _notifications.initialize(
      defaultIcon,
      channels,
      channelGroups: channelGroups,
      debug: debug,
    );
  }

  @override
  Future<bool> setListeners({
    required ActionHandler onActionReceivedMethod,
    NotificationHandler? onNotificationCreatedMethod,
    NotificationHandler? onNotificationDisplayedMethod,
    ActionHandler? onDismissActionReceivedMethod,
  }) {
    return _notifications.setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: onDismissActionReceivedMethod,
    );
  }

  @override
  Future<bool> isNotificationAllowed() => _notifications.isNotificationAllowed();

  @override
  Future<bool> requestPermissionToSendNotifications() => _notifications.requestPermissionToSendNotifications();
}

class AwesomeLocalNotificationService implements NotificationLocalNotifications {
  AwesomeLocalNotificationService({
    AwesomeLocalNotificationsGateway? gateway,
    NotificationChannelConfig? channelConfig,
  }) : _gateway = gateway ?? DefaultAwesomeLocalNotificationsGateway(),
       _channelConfig = channelConfig ?? NotificationConstants.defaultChannel;

  final AwesomeLocalNotificationsGateway _gateway;
  final NotificationChannelConfig _channelConfig;
  Future<void>? _initializeFuture;
  Future<void>? _registerListenersFuture;
  final StreamController<TransportLocalAction> _actionController = StreamController<TransportLocalAction>.broadcast(sync: true);

  @override
  Stream<TransportLocalAction> get actionStream => _actionController.stream;

  @override
  Future<void> initialize() => _initializeFuture ??= _initialize();

  @override
  Future<void> registerListeners() => _registerListenersFuture ??= _registerListeners();

  @override
  Future<TransportLocalAction?> getInitialAction() async {
    final action = await _gateway.getInitialNotificationAction(removeFromActionEvents: true);
    if (action == null) {
      return null;
    }
    return _mapReceivedAction(action);
  }

  @override
  Future<void> show(NotificationRequest request) async {
    await initialize();
    await _gateway.createNotification(content: _buildContent(request));
  }

  @override
  Future<void> schedule(NotificationScheduleRequest request) async {
    await initialize();
    await _gateway.createNotification(
      content: _buildContent(request.notification),
      schedule: await _buildSchedule(request),
    );
  }

  @override
  Future<void> cancel(int id) async {
    await _gateway.cancel(id);
  }

  @override
  Future<void> cancelSchedule(int id) => _gateway.cancelSchedule(id);

  @override
  Future<void> cancelAll() async {
    await _gateway.cancelAll();
  }

  @override
  Future<void> cancelAllSchedules() => _gateway.cancelAllSchedules();

  @override
  Future<bool> isPermissionGranted() => _gateway.isNotificationAllowed();

  @override
  Future<bool> requestPermission() => _gateway.requestPermissionToSendNotifications();

  @override
  Future<void> dispose() async {
    await _actionController.close();
  }

  Future<void> _initialize() async {
    await _gateway.initialize(
      null,
      <NotificationChannel>[
        NotificationChannel(
          channelGroupKey: _channelConfig.channelGroupKey,
          channelKey: _channelConfig.channelKey,
          channelName: _channelConfig.channelName,
          channelDescription: _channelConfig.channelDescription,
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          channelShowBadge: true,
          onlyAlertOnce: true,
          playSound: true,
          criticalAlerts: true,
        ),
      ],
      channelGroups: <NotificationChannelGroup>[
        NotificationChannelGroup(
          channelGroupKey: _channelConfig.channelGroupKey,
          channelGroupName: _channelConfig.channelGroupName,
        ),
      ],
      debug: false,
    );
  }

  Future<void> _registerListeners() async {
    await initialize();
    await _gateway.setListeners(
      onActionReceivedMethod: _handleActionReceived,
    );
  }

  NotificationContent _buildContent(NotificationRequest request) {
    return NotificationContent(
      id: request.id ?? DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      channelKey: _channelConfig.channelKey,
      title: request.title,
      body: request.body,
      summary: request.summary,
      bigPicture: request.imageUrl,
      payload: request.payload,
      actionType: ActionType.Default,
      notificationLayout: request.imageUrl == null ? NotificationLayout.Default : NotificationLayout.BigPicture,
    );
  }

  Future<NotificationSchedule> _buildSchedule(NotificationScheduleRequest request) async {
    if (request.scheduledAt != null) {
      return NotificationCalendar.fromDate(
        date: request.scheduledAt!,
        repeats: request.repeats,
        preciseAlarm: request.preciseAlarm,
      );
    }

    return NotificationInterval(
      interval: request.interval!,
      repeats: request.repeats,
      preciseAlarm: request.preciseAlarm,
      timeZone: await _gateway.getLocalTimeZoneIdentifier(),
    );
  }

  Future<void> _handleActionReceived(ReceivedAction action) async {
    if (_actionController.isClosed) {
      return;
    }
    _actionController.add(_mapReceivedAction(action));
  }

  TransportLocalAction _mapReceivedAction(ReceivedAction action) {
    final payload = <String, String>{};
    final rawPayload = action.payload ?? const <String, String?>{};

    for (final entry in rawPayload.entries) {
      if (entry.value != null) {
        payload[entry.key] = entry.value!;
      }
    }

    return TransportLocalAction(
      id: action.id ?? 0,
      title: action.title,
      body: action.body,
      payload: payload,
      actionKey: action.buttonKeyPressed.isEmpty ? null : action.buttonKeyPressed,
      inputText: action.buttonKeyInput.isEmpty ? null : action.buttonKeyInput,
      performedAt: action.actionDate ?? DateTime.now(),
      fromBackground: action.actionLifeCycle == NotificationLifeCycle.Background,
      fromTerminated: action.actionLifeCycle == NotificationLifeCycle.Terminated,
    );
  }
}
