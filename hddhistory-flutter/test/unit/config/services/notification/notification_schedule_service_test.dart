import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/config/services/services.dart';

void main() {
  group('NotificationScheduleService', () {
    test('delegates schedule requests to the local adapter', () async {
      final localNotifications = _FakeLocalNotifications();
      final service = NotificationScheduleService(localNotifications);
      const request = NotificationScheduleRequest(
        notification: NotificationRequest(title: 'Practice'),
        interval: Duration(hours: 1),
      );

      await service.schedule(request);

      expect(localNotifications.lastScheduledRequest, request);
      await localNotifications.dispose();
    });

    test('cancels both delivered and scheduled notifications', () async {
      final localNotifications = _FakeLocalNotifications();
      final service = NotificationScheduleService(localNotifications);

      await service.cancel(7);

      expect(localNotifications.cancelledIds, <int>[7]);
      expect(localNotifications.cancelledScheduleIds, <int>[7]);
      await localNotifications.dispose();
    });

    test('cancels all notifications and schedules', () async {
      final localNotifications = _FakeLocalNotifications();
      final service = NotificationScheduleService(localNotifications);

      await service.cancelAll();

      expect(localNotifications.cancelAllCalls, 1);
      expect(localNotifications.cancelAllSchedulesCalls, 1);
      await localNotifications.dispose();
    });
  });
}

class _FakeLocalNotifications implements NotificationLocalNotifications {
  final StreamController<TransportLocalAction> _controller = StreamController<TransportLocalAction>.broadcast(sync: true);
  NotificationScheduleRequest? lastScheduledRequest;
  final List<int> cancelledIds = <int>[];
  final List<int> cancelledScheduleIds = <int>[];
  int cancelAllCalls = 0;
  int cancelAllSchedulesCalls = 0;

  @override
  Stream<TransportLocalAction> get actionStream => _controller.stream;

  @override
  Future<void> cancel(int id) async => cancelledIds.add(id);

  @override
  Future<void> cancelAll() async => cancelAllCalls += 1;

  @override
  Future<void> cancelAllSchedules() async => cancelAllSchedulesCalls += 1;

  @override
  Future<void> cancelSchedule(int id) async => cancelledScheduleIds.add(id);

  @override
  Future<void> dispose() => _controller.close();

  @override
  Future<TransportLocalAction?> getInitialAction() async => null;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> isPermissionGranted() async => true;

  @override
  Future<void> registerListeners() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedule(NotificationScheduleRequest request) async {
    lastScheduledRequest = request;
  }

  @override
  Future<void> show(NotificationRequest request) async {}
}
