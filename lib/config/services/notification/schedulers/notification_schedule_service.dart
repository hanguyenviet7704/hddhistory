import '../adapters/awesome_local_notification_service.dart';
import '../notification_core_config.dart';

class NotificationScheduleService {
  NotificationScheduleService(this._localNotifications);

  final NotificationLocalNotifications _localNotifications;

  Future<void> schedule(NotificationScheduleRequest request) => _localNotifications.schedule(request);

  Future<void> cancel(int id) async {
    await _localNotifications.cancel(id);
    await _localNotifications.cancelSchedule(id);
  }

  Future<void> cancelAll() async {
    await _localNotifications.cancelAll();
    await _localNotifications.cancelAllSchedules();
  }
}
