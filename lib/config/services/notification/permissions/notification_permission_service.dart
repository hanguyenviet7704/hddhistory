part of '../../services.dart';

abstract interface class NotificationPushPermissionProvider {
  Future<NotificationPermissionStatus> getPermissionStatus();
  Future<NotificationPermissionStatus> requestPermission();
}

abstract interface class NotificationLocalPermissionProvider {
  Future<bool> isPermissionGranted();
  Future<bool> requestPermission();
}

class NotificationPermissionService {
  NotificationPermissionService({
    required NotificationPushPermissionProvider pushPermissionProvider,
    required NotificationLocalPermissionProvider localPermissionProvider,
    bool? isApplePlatform,
    bool? isAndroidPlatform,
  }) : _pushPermissionProvider = pushPermissionProvider,
       _localPermissionProvider = localPermissionProvider,
       _isApplePlatform = isApplePlatform ?? (Platform.isIOS || Platform.isMacOS),
       _isAndroidPlatform = isAndroidPlatform ?? Platform.isAndroid;

  final NotificationPushPermissionProvider _pushPermissionProvider;
  final NotificationLocalPermissionProvider _localPermissionProvider;
  final bool _isApplePlatform;
  final bool _isAndroidPlatform;

  Future<NotificationPermissionState> getPermissionState({
    required bool enablePush,
    required bool enableLocal,
  }) async {
    if (!enablePush && !enableLocal) {
      return _disabledState();
    }

    if (_isApplePlatform) {
      return _getApplePermissionState(enablePush: enablePush, enableLocal: enableLocal);
    }

    if (!_isAndroidPlatform) {
      return _unsupportedState(enablePush: enablePush, enableLocal: enableLocal);
    }

    return _getSystemPermissionState(
      enablePush: enablePush,
      enableLocal: enableLocal,
      shouldRequest: false,
    );
  }

  Future<NotificationPermissionState> requestPermission({
    required bool enablePush,
    required bool enableLocal,
  }) async {
    if (!enablePush && !enableLocal) {
      return _disabledState();
    }

    if (_isApplePlatform) {
      return _requestApplePermission(enablePush: enablePush, enableLocal: enableLocal);
    }

    if (!_isAndroidPlatform) {
      return _unsupportedState(enablePush: enablePush, enableLocal: enableLocal);
    }

    return _getSystemPermissionState(
      enablePush: enablePush,
      enableLocal: enableLocal,
      shouldRequest: true,
    );
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }

  NotificationPermissionState _disabledState() {
    return const NotificationPermissionState(
      status: NotificationPermissionStatus.notDetermined,
      systemNotificationsEnabled: false,
      localNotificationsEnabled: false,
      pushNotificationsEnabled: false,
      canRequest: false,
      canOpenSettings: false,
    );
  }

  NotificationPermissionState _unsupportedState({
    required bool enablePush,
    required bool enableLocal,
  }) {
    return NotificationPermissionState(
      status: NotificationPermissionStatus.unsupported,
      systemNotificationsEnabled: false,
      localNotificationsEnabled: false,
      pushNotificationsEnabled: false,
      canRequest: false,
      canOpenSettings: enablePush || enableLocal,
    );
  }

  Future<NotificationPermissionState> _getApplePermissionState({
    required bool enablePush,
    required bool enableLocal,
  }) async {
    final pushStatus = enablePush ? await _pushPermissionProvider.getPermissionStatus() : NotificationPermissionStatus.notDetermined;
    final localAllowed = enableLocal ? (enablePush ? pushStatus.isAuthorized : await _localPermissionProvider.isPermissionGranted()) : false;
    final status = enablePush ? pushStatus : (localAllowed ? NotificationPermissionStatus.authorized : NotificationPermissionStatus.denied);

    return NotificationPermissionState(
      status: status,
      systemNotificationsEnabled: status.isAuthorized || localAllowed,
      localNotificationsEnabled: enableLocal && localAllowed,
      pushNotificationsEnabled: enablePush && status.isAuthorized,
      canRequest: enablePush ? status.canRequest : !localAllowed,
      canOpenSettings: enablePush || enableLocal,
    );
  }

  Future<NotificationPermissionState> _requestApplePermission({
    required bool enablePush,
    required bool enableLocal,
  }) async {
    final pushStatus = enablePush ? await _pushPermissionProvider.requestPermission() : NotificationPermissionStatus.notDetermined;
    final localAllowed = enableLocal ? (enablePush ? pushStatus.isAuthorized : await _localPermissionProvider.requestPermission()) : false;
    final status = enablePush ? pushStatus : (localAllowed ? NotificationPermissionStatus.authorized : NotificationPermissionStatus.denied);

    return NotificationPermissionState(
      status: status,
      systemNotificationsEnabled: status.isAuthorized || localAllowed,
      localNotificationsEnabled: enableLocal && localAllowed,
      pushNotificationsEnabled: enablePush && status.isAuthorized,
      canRequest: enablePush ? status.canRequest : !localAllowed,
      canOpenSettings: enablePush || enableLocal,
    );
  }

  Future<NotificationPermissionState> _getSystemPermissionState({
    required bool enablePush,
    required bool enableLocal,
    required bool shouldRequest,
  }) async {
    final permissionStatus = shouldRequest ? await Permission.notification.request() : await Permission.notification.status;
    final mappedStatus = _mapPermissionStatus(permissionStatus);
    final isGranted = mappedStatus.isAuthorized;

    return NotificationPermissionState(
      status: mappedStatus,
      systemNotificationsEnabled: isGranted,
      localNotificationsEnabled: enableLocal && isGranted,
      pushNotificationsEnabled: enablePush && isGranted,
      canRequest: permissionStatus.isDenied,
      canOpenSettings: !isGranted,
    );
  }

  NotificationPermissionStatus _mapPermissionStatus(PermissionStatus permissionStatus) {
    if (permissionStatus.isGranted || permissionStatus.isLimited) {
      return NotificationPermissionStatus.authorized;
    }
    if (permissionStatus.isDenied) {
      return NotificationPermissionStatus.notDetermined;
    }
    if (permissionStatus.isPermanentlyDenied || permissionStatus.isRestricted) {
      return NotificationPermissionStatus.denied;
    }
    return NotificationPermissionStatus.denied;
  }
}
