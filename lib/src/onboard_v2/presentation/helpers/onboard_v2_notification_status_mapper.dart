part of '../../onboard_v2.dart';

enum OnboardV2NotificationStatus {
  authorized('authorized'),
  denied('denied'),
  restricted('restricted'),
  permanentlyDenied('permanently_denied'),
  alreadyAuthorized('already_authorized'),
  alreadyDenied('already_denied'),
  unsupported('unsupported'),
  maybeLater('maybe_later'),
  unknown('unknown')
  ;

  const OnboardV2NotificationStatus(this.trackingValue);

  final String trackingValue;
}

abstract final class OnboardV2NotificationStatusMapper {
  static OnboardV2NotificationStatus fromCurrentState(NotificationState state) {
    if (!state.hasLoadedPermissionState) return OnboardV2NotificationStatus.unknown;

    if (state.permissionStatus == NotificationPermissionStatus.unsupported) {
      return OnboardV2NotificationStatus.unsupported;
    }

    if (state.permissionStatus.isAuthorized) {
      return OnboardV2NotificationStatus.alreadyAuthorized;
    }

    if (state.permissionStatus == NotificationPermissionStatus.denied) {
      return state.canOpenSettings ? OnboardV2NotificationStatus.permanentlyDenied : OnboardV2NotificationStatus.alreadyDenied;
    }

    if (!state.canRequestPermission && !state.canOpenSettings) {
      return OnboardV2NotificationStatus.restricted;
    }

    if (state.isCapabilityUnavailable) {
      return OnboardV2NotificationStatus.unsupported;
    }

    return OnboardV2NotificationStatus.unknown;
  }

  static OnboardV2NotificationStatus fromRequestResult(NotificationState state) {
    if (state.permissionStatus == NotificationPermissionStatus.unsupported || state.isCapabilityUnavailable) {
      return OnboardV2NotificationStatus.unsupported;
    }

    return switch (state.permissionStatus) {
      NotificationPermissionStatus.authorized || NotificationPermissionStatus.provisional => OnboardV2NotificationStatus.authorized,
      NotificationPermissionStatus.denied => OnboardV2NotificationStatus.denied,
      NotificationPermissionStatus.notDetermined => OnboardV2NotificationStatus.unknown,
      NotificationPermissionStatus.unsupported => OnboardV2NotificationStatus.unsupported,
    };
  }

  static OnboardV2NotificationStatus maybeLater() => OnboardV2NotificationStatus.maybeLater;
}
