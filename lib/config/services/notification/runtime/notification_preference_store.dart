part of '../../services.dart';

typedef NotificationPreferenceReadAction = Future<bool> Function();
typedef NotificationPreferenceWriteAction = Future<void> Function(bool enabled);

FlutterSecureStorage? _notificationPreferenceStorage;

NotificationPreferenceReadAction _notificationPreferenceReadAction = _defaultNotificationPreferenceReadAction;
NotificationPreferenceWriteAction _notificationPreferenceWriteAction = _defaultNotificationPreferenceWriteAction;

FlutterSecureStorage _resolveNotificationPreferenceStorage() {
  return _notificationPreferenceStorage ??= FlutterSecureStorage(
    aOptions: const AndroidOptions(resetOnError: true),
    iOptions: const IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
}

Future<bool> _defaultNotificationPreferenceReadAction() async {
  final value = await _resolveNotificationPreferenceStorage().read(
    key: LocalStoreKey.notificationAppPreferenceEnabled,
  );
  return bool.tryParse(value ?? 'true') ?? true;
}

Future<void> _defaultNotificationPreferenceWriteAction(bool enabled) {
  return _resolveNotificationPreferenceStorage().write(
    key: LocalStoreKey.notificationAppPreferenceEnabled,
    value: enabled.toString(),
  );
}

Future<bool> isAppNotificationPreferenceEnabled() {
  return _notificationPreferenceReadAction();
}

Future<void> persistAppNotificationPreference(bool enabled) {
  return _notificationPreferenceWriteAction(enabled);
}

@visibleForTesting
void debugConfigureNotificationPreferenceStore({
  NotificationPreferenceReadAction? readAction,
  NotificationPreferenceWriteAction? writeAction,
}) {
  _notificationPreferenceReadAction = readAction ?? _defaultNotificationPreferenceReadAction;
  _notificationPreferenceWriteAction = writeAction ?? _defaultNotificationPreferenceWriteAction;
}
