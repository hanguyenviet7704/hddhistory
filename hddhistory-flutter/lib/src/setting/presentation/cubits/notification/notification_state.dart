part of '../../../setting.dart';

@freezed
abstract class NotificationState with _$NotificationState {
  const NotificationState._();

  const factory NotificationState({
    @Default(false) bool hasInitializedPreference,
    @Default(false) bool hasLoadedPermissionState,
    @Default(false) bool notificationsEnabled,
    @Default(NotificationPermissionStatus.notDetermined) NotificationPermissionStatus permissionStatus,
    @Default(false) bool systemNotificationsEnabled,
    @Default(false) bool localNotificationsEnabled,
    @Default(false) bool pushNotificationsEnabled,
    @Default(false) bool canRequestPermission,
    @Default(false) bool canOpenSettings,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _NotificationState;

  factory NotificationState.initial() => const NotificationState();

  factory NotificationState.fromJson(Map<String, dynamic> json) => _$NotificationStateFromJson(json);
}

extension NotificationStateX on NotificationState {
  bool get isPermissionGranted => permissionStatus.isAuthorized;

  bool get isEffectivelyEnabled => notificationsEnabled && (systemNotificationsEnabled || localNotificationsEnabled || pushNotificationsEnabled || isPermissionGranted);

  bool get isCapabilityUnavailable =>
      hasLoadedPermissionState &&
      (permissionStatus == NotificationPermissionStatus.unsupported ||
          (!canRequestPermission && !canOpenSettings && !systemNotificationsEnabled && !localNotificationsEnabled && !pushNotificationsEnabled));

  bool get shouldSkipOnboardingGate => hasLoadedPermissionState && isCapabilityUnavailable;
}
