part of '../../../setting.dart';

@lazySingleton
class NotificationCubit extends HydratedCubit<NotificationState> {
  NotificationCubit() : super(NotificationState.initial());

  @override
  NotificationState fromJson(Map<String, dynamic> json) => NotificationState.fromJson(json);

  @override
  Map<String, dynamic> toJson(NotificationState state) => {
    'hasInitializedPreference': state.hasInitializedPreference,
    'notificationsEnabled': state.notificationsEnabled,
  };

  Future<NotificationState> refreshPermissionState({
    bool syncAuthorizedPreference = false,
    bool syncPreferenceToPermissionState = false,
  }) async {
    assert(
      !(syncAuthorizedPreference && syncPreferenceToPermissionState),
      'Use either syncAuthorizedPreference or syncPreferenceToPermissionState, not both.',
    );
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final permissionState = await NotificationService.getPermissionState();
      final shouldSyncPreference = syncAuthorizedPreference && permissionState.isAuthorized && !state.hasInitializedPreference;
      final shouldAdoptPermissionState = syncPreferenceToPermissionState;
      return _applyPermissionState(
        permissionState,
        notificationsEnabled: shouldAdoptPermissionState ? permissionState.isAuthorized : (shouldSyncPreference ? true : state.notificationsEnabled),
        hasInitializedPreference: shouldAdoptPermissionState ? true : (shouldSyncPreference || state.hasInitializedPreference),
      );
    } catch (error) {
      return _emitError(error);
    }
  }

  Future<NotificationState> enableFromOnboardingGate() => _enableNotifications();

  Future<void> openSettingsFromSettings() async {
    emit(state.copyWith(errorMessage: null));

    try {
      await NotificationService.openSettings();
    } catch (error) {
      _emitError(error);
    }
  }

  Future<NotificationState> toggleFromSettings(bool value) {
    if (value) {
      return _enableNotifications();
    }
    return disableAppPreference();
  }

  Future<NotificationState> disableAppPreference() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      await NotificationService.cancelAll();
      final permissionState = await NotificationService.getPermissionState();
      return _applyPermissionState(
        permissionState,
        notificationsEnabled: false,
        hasInitializedPreference: true,
      );
    } catch (error) {
      return _emitError(error);
    }
  }

  void clearError() {
    if (state.errorMessage == null) return;
    emit(state.copyWith(errorMessage: null));
  }

  Future<NotificationState> _enableNotifications() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final currentPermissionState = await NotificationService.getPermissionState();
      if (currentPermissionState.isAuthorized) {
        return _applyPermissionState(
          currentPermissionState,
          notificationsEnabled: true,
          hasInitializedPreference: true,
        );
      }

      if (currentPermissionState.canRequest) {
        final requestedPermissionState = await NotificationService.requestPermission();
        return _applyPermissionState(
          requestedPermissionState,
          notificationsEnabled: requestedPermissionState.isAuthorized ? true : state.notificationsEnabled,
          hasInitializedPreference: requestedPermissionState.isAuthorized || state.hasInitializedPreference,
        );
      }

      if (currentPermissionState.canOpenSettings) {
        await NotificationService.openSettings();
        final refreshedPermissionState = await NotificationService.getPermissionState();
        return _applyPermissionState(
          refreshedPermissionState,
          notificationsEnabled: refreshedPermissionState.isAuthorized ? true : state.notificationsEnabled,
          hasInitializedPreference: refreshedPermissionState.isAuthorized || state.hasInitializedPreference,
        );
      }

      return _applyPermissionState(
        currentPermissionState,
        notificationsEnabled: state.notificationsEnabled,
        hasInitializedPreference: state.hasInitializedPreference,
      );
    } catch (error) {
      return _emitError(error);
    }
  }

  NotificationState _applyPermissionState(
    NotificationPermissionState permissionState, {
    required bool notificationsEnabled,
    required bool hasInitializedPreference,
  }) {
    unawaited(_persistAppPreferenceSafely(notificationsEnabled));
    final nextState = state.copyWith(
      hasInitializedPreference: hasInitializedPreference,
      hasLoadedPermissionState: true,
      notificationsEnabled: notificationsEnabled,
      permissionStatus: permissionState.status,
      systemNotificationsEnabled: permissionState.systemNotificationsEnabled,
      localNotificationsEnabled: permissionState.localNotificationsEnabled,
      pushNotificationsEnabled: permissionState.pushNotificationsEnabled,
      canRequestPermission: permissionState.canRequest,
      canOpenSettings: permissionState.canOpenSettings,
      isLoading: false,
      errorMessage: null,
    );
    emit(nextState);
    // Once per off→on transition, not once per call: this method also runs on
    // every plain load of the notification screen, and re-POSTing the same token
    // each time someone opens Settings is noise. The cubit is a lazySingleton,
    // so the flag spans the app run — which also makes the first authorized load
    // after launch a cheap self-heal if the server somehow has no token.
    if (permissionState.isAuthorized) {
      if (!_pushRegistrationSynced) {
        _pushRegistrationSynced = true;
        _syncPushRegistrationSafely();
      }
    } else {
      _pushRegistrationSynced = false;
    }
    return nextState;
  }

  /// Whether this app run has already handed the server a token while
  /// permission was granted. Reset whenever permission drops, so turning
  /// notifications off and on again re-registers.
  bool _pushRegistrationSynced = false;

  /// Hands the server this device's FCM token the moment permission allows one.
  ///
  /// Not left to `AuthBloc`'s token-refresh listener alone: that only fires when
  /// FCM mints a NEW token. Someone who turns notifications off in iOS Settings
  /// and back on keeps the token they already had, so no refresh event ever
  /// arrives — and until this call existed, the server went on believing that
  /// device had no token and skipped it in every scheduled send.
  ///
  /// Reached through the injector rather than a constructor dependency because
  /// AuthBloc already depends on this feature's siblings; taking it as a field
  /// here would close the loop. Best-effort by design — [syncPushRegistration]
  /// swallows and logs its own failures.
  void _syncPushRegistrationSafely() {
    try {
      unawaited(AppDI.injector.get<AuthBloc>().syncPushRegistration());
    } catch (error) {
      LogDev.warning('[NotificationCubit] could not sync push registration: $error');
    }
  }

  Future<void> _persistAppPreferenceSafely(bool notificationsEnabled) async {
    try {
      await persistAppNotificationPreference(notificationsEnabled);
    } catch (error) {
      LogDev.error('[NotificationCubit] Failed to persist app notification preference: $error');
    }
  }

  NotificationState _emitError(Object error) {
    LogDev.error('[NotificationCubit] Failed to update notification state: $error');
    final nextState = state.copyWith(isLoading: false, errorMessage: error.toString());
    emit(nextState);
    return nextState;
  }
}
