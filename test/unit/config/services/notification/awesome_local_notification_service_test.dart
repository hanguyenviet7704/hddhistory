import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/config/services/services.dart';

void main() {
  group('AwesomeLocalNotificationService', () {
    test('registers a valid background entrypoint for action callbacks', () async {
      final gateway = _FakeAwesomeLocalNotificationsGateway();
      final service = AwesomeLocalNotificationService(gateway: gateway);

      await service.registerListeners();

      expect(gateway.onActionReceivedMethod, same(awesomeLocalNotificationActionEntryPoint));
      expect(PluginUtilities.getCallbackHandle(gateway.onActionReceivedMethod!), isNotNull);

      await service.dispose();
    });

    test('forwards received actions into the local action stream', () async {
      final gateway = _FakeAwesomeLocalNotificationsGateway();
      final service = AwesomeLocalNotificationService(gateway: gateway);
      final nextAction = service.actionStream.first;

      await service.registerListeners();
      await gateway.onActionReceivedMethod!(
        _receivedAction(
          id: 42,
          title: 'Practice reminder',
          body: 'Time to review',
          payload: const <String, String?>{'lessonId': 'lesson-1'},
          buttonKeyPressed: 'open',
          actionLifeCycle: NotificationLifeCycle.Foreground,
          actionDate: '2026-03-16 10:00:00',
        ),
      );

      final action = await nextAction.timeout(const Duration(seconds: 1));

      expect(action.id, 42);
      expect(action.title, 'Practice reminder');
      expect(action.body, 'Time to review');
      expect(action.payload, <String, String>{'lessonId': 'lesson-1'});
      expect(action.actionKey, 'open');
      expect(action.fromBackground, isFalse);
      expect(action.fromTerminated, isFalse);

      await service.dispose();
    });

    test('buffers actions received before the stream listener is attached', () async {
      final gateway = _FakeAwesomeLocalNotificationsGateway();
      final service = AwesomeLocalNotificationService(gateway: gateway);
      final completer = Completer<TransportLocalAction>();

      await service.registerListeners();
      await gateway.onActionReceivedMethod!(
        _receivedAction(
          id: 7003,
          title: 'TERM Verify',
          body: 'Tap terminated verify',
          payload: const <String, String?>{'case': 'terminated'},
          actionLifeCycle: NotificationLifeCycle.Terminated,
          actionDate: '2026-03-17 08:50:47',
        ),
      );

      final subscription = service.actionStream.listen((action) {
        if (!completer.isCompleted) {
          completer.complete(action);
        }
      });

      final action = await completer.future.timeout(const Duration(seconds: 1));

      expect(action.id, 7003);
      expect(action.title, 'TERM Verify');
      expect(action.fromBackground, isFalse);
      expect(action.fromTerminated, isTrue);

      await subscription.cancel();
      await service.dispose();
    });

    test('maps initial actions and delegates show schedule cancel and permission calls', () async {
      final gateway = _FakeAwesomeLocalNotificationsGateway(
        initialAction: _receivedAction(
          id: 9,
          title: 'Initial action',
          body: 'Opened from tray',
          payload: const <String, String?>{'kind': 'initial'},
          actionLifeCycle: NotificationLifeCycle.Background,
          actionDate: '2026-03-17 09:00:00',
        ),
        permissionGranted: true,
        requestPermissionResult: true,
      );
      final service = AwesomeLocalNotificationService(gateway: gateway);

      await service.show(
        const NotificationRequest(
          id: 1,
          title: 'Now',
          body: 'Show immediately',
          summary: 'summary',
          imageUrl: 'https://cdn.example.com/now.png',
          payload: <String, String>{'kind': 'show'},
        ),
      );
      await service.schedule(
        const NotificationScheduleRequest(
          notification: NotificationRequest(id: 2, title: 'Interval'),
          interval: Duration(minutes: 30),
          repeats: true,
          preciseAlarm: false,
        ),
      );
      await service.schedule(
        NotificationScheduleRequest(
          notification: const NotificationRequest(id: 3, title: 'Calendar'),
          scheduledAt: DateTime(2026, 3, 20, 9, 30),
        ),
      );
      final initialAction = await service.getInitialAction();
      final isPermissionGranted = await service.isPermissionGranted();
      final permissionRequested = await service.requestPermission();
      await service.cancel(1);
      await service.cancelSchedule(2);
      await service.cancelAll();
      await service.cancelAllSchedules();

      expect(gateway.initializeCalls, 1);
      expect(gateway.createdNotifications, hasLength(3));
      expect(gateway.createdNotifications.first.title, 'Now');
      expect(gateway.createdNotifications.first.bigPicture, 'https://cdn.example.com/now.png');
      expect(gateway.createdNotifications.first.payload, <String, String>{'kind': 'show'});
      expect(gateway.createdSchedules[1], isNull);
      expect(gateway.createdSchedules[2], isA<NotificationInterval>());
      expect(gateway.createdSchedules[3], isA<NotificationCalendar>());
      expect(initialAction?.id, 9);
      expect(initialAction?.fromBackground, isTrue);
      expect(initialAction?.payload['kind'], 'initial');
      expect(isPermissionGranted, isTrue);
      expect(permissionRequested, isTrue);
      expect(gateway.cancelledIds, <int>[1]);
      expect(gateway.cancelledScheduleIds, <int>[2]);
      expect(gateway.cancelAllCalls, 1);
      expect(gateway.cancelAllSchedulesCalls, 1);

      await service.dispose();
    });

    test('normalizes oversized ids for create and cancel operations', () async {
      final gateway = _FakeAwesomeLocalNotificationsGateway();
      final service = AwesomeLocalNotificationService(gateway: gateway);
      final oversizedId = 9223372036854775807;

      await service.show(
        NotificationRequest(
          id: oversizedId,
          title: 'Oversized show',
        ),
      );
      await service.schedule(
        NotificationScheduleRequest(
          notification: NotificationRequest(
            id: oversizedId,
            title: 'Oversized schedule',
          ),
          interval: const Duration(minutes: 5),
        ),
      );
      await service.cancel(oversizedId);
      await service.cancelSchedule(oversizedId);

      final normalizedIds = gateway.createdNotifications.map((content) => content.id).toSet();

      expect(gateway.createdNotifications, hasLength(2));
      expect(normalizedIds, hasLength(1));
      expect(
        normalizedIds.single,
        allOf(
          greaterThanOrEqualTo(-0x80000000),
          lessThanOrEqualTo(0x7FFFFFFF),
        ),
      );
      expect(gateway.cancelledIds, <int>[normalizedIds.single!]);
      expect(gateway.cancelledScheduleIds, <int>[normalizedIds.single!]);

      await service.dispose();
    });

    test('skips show and schedule when notifications are disabled', () async {
      final gateway = _FakeAwesomeLocalNotificationsGateway(
        permissionGranted: false,
      );
      final service = AwesomeLocalNotificationService(gateway: gateway);

      await service.show(
        const NotificationRequest(
          id: 11,
          title: 'Disabled show',
        ),
      );
      await service.schedule(
        const NotificationScheduleRequest(
          notification: NotificationRequest(
            id: 12,
            title: 'Disabled schedule',
          ),
          interval: Duration(minutes: 10),
        ),
      );

      expect(gateway.createdNotifications, isEmpty);

      await service.dispose();
    });

    test('swallows insufficient permission errors returned by the platform', () async {
      final gateway = _FakeAwesomeLocalNotificationsGateway(
        createNotificationError: PlatformException(
          code: 'INSUFFICIENT_PERMISSIONS',
          message: 'Notifications are disabled',
        ),
      );
      final service = AwesomeLocalNotificationService(gateway: gateway);

      await service.show(
        const NotificationRequest(
          id: 13,
          title: 'Platform denied',
        ),
      );

      expect(gateway.createdNotifications, hasLength(1));

      await service.dispose();
    });

    test('forwards action maps sent through the isolate port and ignores unsupported payload types', () async {
      final gateway = _FakeAwesomeLocalNotificationsGateway();
      final service = AwesomeLocalNotificationService(gateway: gateway);
      final received = <TransportLocalAction>[];
      final subscription = service.actionStream.listen(received.add);

      await service.registerListeners();
      final actionPort = IsolateNameServer.lookupPortByName('hddhistory.notification.action.port');

      expect(actionPort, isNotNull);

      actionPort!.send('unsupported');
      actionPort.send(
        _receivedAction(
          id: 77,
          title: 'Port forwarded',
          payload: const <String, String?>{'source': 'port'},
          actionLifeCycle: NotificationLifeCycle.Foreground,
        ).toMap(),
      );
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.single.id, 77);
      expect(received.single.payload['source'], 'port');

      await subscription.cancel();
      await service.dispose();
    });

    test('drops entrypoint payloads gracefully when the action port is unavailable', () async {
      final gateway = _FakeAwesomeLocalNotificationsGateway();
      final service = AwesomeLocalNotificationService(gateway: gateway);

      await service.registerListeners();
      await service.dispose();

      await awesomeLocalNotificationActionEntryPoint(
        _receivedAction(
          id: 404,
          title: 'Dropped',
          actionLifeCycle: NotificationLifeCycle.Terminated,
        ),
      );
    });

    test('forwards entrypoint payloads through the named port when no service is attached', () async {
      final receivePort = ReceivePort();
      final receivedMessages = <dynamic>[];
      final subscription = receivePort.listen(receivedMessages.add);

      IsolateNameServer.removePortNameMapping('hddhistory.notification.action.port');
      IsolateNameServer.registerPortWithName(receivePort.sendPort, 'hddhistory.notification.action.port');

      await awesomeLocalNotificationActionEntryPoint(
        _receivedAction(
          id: 505,
          title: 'Port relay',
          actionLifeCycle: NotificationLifeCycle.Terminated,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(receivedMessages, hasLength(1));
      expect((receivedMessages.single as Map<dynamic, dynamic>)['id'], 505);

      await subscription.cancel();
      receivePort.close();
      IsolateNameServer.removePortNameMapping('hddhistory.notification.action.port');
    });

    test('returns null when there is no initial action', () async {
      final service = AwesomeLocalNotificationService(
        gateway: _FakeAwesomeLocalNotificationsGateway(),
      );

      expect(await service.getInitialAction(), isNull);

      await service.dispose();
    });
  });

  group('DefaultAwesomeLocalNotificationsGateway', () {
    test('delegates operations to the AwesomeNotifications SDK instance', () async {
      final notifications = _FakeAwesomeNotifications();
      final gateway = DefaultAwesomeLocalNotificationsGateway(notifications: notifications);
      Future<void> actionHandler(ReceivedAction action) async {}

      await gateway.initialize(
        null,
        const <NotificationChannel>[],
        channelGroups: const <NotificationChannelGroup>[],
        debug: true,
      );
      await gateway.setListeners(onActionReceivedMethod: actionHandler);
      await gateway.createNotification(
        content: NotificationContent(id: 1, channelKey: 'default'),
      );
      await gateway.getInitialNotificationAction(removeFromActionEvents: true);
      await gateway.getLocalTimeZoneIdentifier();
      await gateway.cancel(1);
      await gateway.cancelSchedule(2);
      await gateway.cancelAll();
      await gateway.cancelAllSchedules();
      await gateway.isNotificationAllowed();
      await gateway.requestPermissionToSendNotifications();

      expect(notifications.initializeCalls, 1);
      expect(notifications.setListenersCalls, 1);
      expect(notifications.createNotificationCalls, 1);
      expect(notifications.getInitialActionCalls, 1);
      expect(notifications.cancelledIds, <int>[1]);
      expect(notifications.cancelledScheduleIds, <int>[2]);
      expect(notifications.cancelAllCalls, 1);
      expect(notifications.cancelAllSchedulesCalls, 1);
      expect(notifications.isNotificationAllowedCalls, 1);
      expect(notifications.requestPermissionCalls, 1);
    });
  });
}

ReceivedAction _receivedAction({
  int? id,
  String? title,
  String? body,
  Map<String, String?>? payload,
  String buttonKeyPressed = '',
  NotificationLifeCycle actionLifeCycle = NotificationLifeCycle.Foreground,
  String? actionDate,
}) {
  final actionDateEntry = actionDate == null ? const <String, dynamic>{} : <String, dynamic>{'actionDate': actionDate};
  return ReceivedAction().fromMap(<String, dynamic>{
    'id': id,
    'title': title,
    'body': body,
    'payload': payload,
    'buttonKeyPressed': buttonKeyPressed,
    'actionLifeCycle': actionLifeCycle.name,
    ...actionDateEntry,
  });
}

class _FakeAwesomeLocalNotificationsGateway implements AwesomeLocalNotificationsGateway {
  _FakeAwesomeLocalNotificationsGateway({
    this.initialAction,
    this.permissionGranted = true,
    this.requestPermissionResult = true,
    this.createNotificationError,
  });

  ActionHandler? onActionReceivedMethod;
  ReceivedAction? initialAction;
  bool permissionGranted;
  bool requestPermissionResult;
  Object? createNotificationError;
  int initializeCalls = 0;
  int cancelAllCalls = 0;
  int cancelAllSchedulesCalls = 0;
  final List<int> cancelledIds = <int>[];
  final List<int> cancelledScheduleIds = <int>[];
  final List<NotificationContent> createdNotifications = <NotificationContent>[];
  final Map<int, NotificationSchedule?> createdSchedules = <int, NotificationSchedule?>{};

  @override
  Future<void> cancel(int id) async => cancelledIds.add(id);

  @override
  Future<void> cancelAll() async => cancelAllCalls += 1;

  @override
  Future<void> cancelAllSchedules() async => cancelAllSchedulesCalls += 1;

  @override
  Future<void> cancelSchedule(int id) async => cancelledScheduleIds.add(id);

  @override
  Future<bool> createNotification({
    required NotificationContent content,
    NotificationSchedule? schedule,
  }) async {
    createdNotifications.add(content);
    createdSchedules[content.id!] = schedule;
    if (createNotificationError case final PlatformException error) {
      throw error;
    }
    return true;
  }

  @override
  Future<ReceivedAction?> getInitialNotificationAction({
    bool removeFromActionEvents = false,
  }) async => initialAction;

  @override
  Future<String> getLocalTimeZoneIdentifier() async => 'UTC';

  @override
  Future<bool> initialize(
    String? defaultIcon,
    List<NotificationChannel> channels, {
    List<NotificationChannelGroup>? channelGroups,
    bool debug = false,
    String? languageCode,
  }) async {
    initializeCalls += 1;
    return true;
  }

  @override
  Future<bool> isNotificationAllowed() async => permissionGranted;

  @override
  Future<bool> requestPermissionToSendNotifications() async => requestPermissionResult;

  @override
  Future<bool> setListeners({
    required ActionHandler onActionReceivedMethod,
    NotificationHandler? onNotificationCreatedMethod,
    NotificationHandler? onNotificationDisplayedMethod,
    ActionHandler? onDismissActionReceivedMethod,
  }) async {
    this.onActionReceivedMethod = onActionReceivedMethod;
    return true;
  }
}

class _FakeAwesomeNotifications extends AwesomeNotifications {
  int initializeCalls = 0;
  int setListenersCalls = 0;
  int createNotificationCalls = 0;
  int getInitialActionCalls = 0;
  int cancelAllCalls = 0;
  int cancelAllSchedulesCalls = 0;
  int isNotificationAllowedCalls = 0;
  int requestPermissionCalls = 0;
  final List<int> cancelledIds = <int>[];
  final List<int> cancelledScheduleIds = <int>[];

  @override
  Future<void> cancel(int id) async => cancelledIds.add(id);

  @override
  Future<void> cancelAll() async => cancelAllCalls += 1;

  @override
  Future<void> cancelAllSchedules() async => cancelAllSchedulesCalls += 1;

  @override
  Future<void> cancelSchedule(int id) async => cancelledScheduleIds.add(id);

  @override
  Future<bool> createNotification({
    required NotificationContent content,
    NotificationSchedule? schedule,
    List<NotificationActionButton>? actionButtons,
    Map<String, NotificationLocalization>? localizations,
  }) async {
    createNotificationCalls += 1;
    return true;
  }

  @override
  Future<ReceivedAction?> getInitialNotificationAction({
    bool removeFromActionEvents = false,
  }) async {
    getInitialActionCalls += 1;
    return null;
  }

  @override
  Future<String> getLocalTimeZoneIdentifier() async => 'UTC';

  @override
  Future<bool> initialize(
    String? defaultIcon,
    List<NotificationChannel> channels, {
    List<NotificationChannelGroup>? channelGroups,
    bool debug = false,
    String? languageCode,
  }) async {
    initializeCalls += 1;
    return true;
  }

  @override
  Future<bool> isNotificationAllowed() async {
    isNotificationAllowedCalls += 1;
    return true;
  }

  @override
  Future<bool> requestPermissionToSendNotifications({
    String? channelKey,
    List<NotificationPermission> permissions = const <NotificationPermission>[
      NotificationPermission.Alert,
      NotificationPermission.Sound,
      NotificationPermission.Badge,
      NotificationPermission.Vibration,
      NotificationPermission.Light,
    ],
  }) async {
    requestPermissionCalls += 1;
    return true;
  }

  @override
  Future<bool> setListeners({
    required ActionHandler onActionReceivedMethod,
    NotificationHandler? onNotificationCreatedMethod,
    NotificationHandler? onNotificationDisplayedMethod,
    ActionHandler? onDismissActionReceivedMethod,
  }) async {
    setListenersCalls += 1;
    return true;
  }
}
