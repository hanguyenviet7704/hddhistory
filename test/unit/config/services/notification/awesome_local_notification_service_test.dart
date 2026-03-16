import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meup/config/services/services.dart';

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
        ReceivedAction().fromMap(<String, dynamic>{
          'id': 42,
          'title': 'Practice reminder',
          'body': 'Time to review',
          'payload': <String, String?>{'lessonId': 'lesson-1'},
          'buttonKeyPressed': 'open',
          'actionLifeCycle': NotificationLifeCycle.Foreground.name,
          'actionDate': '2026-03-16 10:00:00',
        }),
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
  });
}

class _FakeAwesomeLocalNotificationsGateway implements AwesomeLocalNotificationsGateway {
  ActionHandler? onActionReceivedMethod;

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> cancelAllSchedules() async {}

  @override
  Future<void> cancelSchedule(int id) async {}

  @override
  Future<bool> createNotification({
    required NotificationContent content,
    NotificationSchedule? schedule,
  }) async => true;

  @override
  Future<ReceivedAction?> getInitialNotificationAction({
    bool removeFromActionEvents = false,
  }) async => null;

  @override
  Future<String> getLocalTimeZoneIdentifier() async => 'UTC';

  @override
  Future<bool> initialize(
    String? defaultIcon,
    List<NotificationChannel> channels, {
    List<NotificationChannelGroup>? channelGroups,
    bool debug = false,
  }) async => true;

  @override
  Future<bool> isNotificationAllowed() async => true;

  @override
  Future<bool> requestPermissionToSendNotifications() async => true;

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
