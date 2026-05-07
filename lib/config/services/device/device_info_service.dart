part of '../services.dart';

abstract interface class IDeviceInfoService {
  Future<String> get deviceToken;
  Future<String> get deviceName;
  Future<void> getAllDeviceInfo();
  Future<int?> getAndroidSdkVersion();
  Future<bool> isAndroid13OrHigher();
  Future<BaseDeviceInfo?> get deviceInfo;
}

@LazySingleton(as: IDeviceInfoService)
class DeviceInfoService implements IDeviceInfoService {
  final ILocalStoreService _localStoreService;
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  final bool? _isIOSOverride;
  final bool? _isAndroidOverride;
  String? _cachedIosDeviceToken;
  Future<String>? _iosDeviceTokenTask;

  DeviceInfoService(
    this._localStoreService, {
    @visibleForTesting bool? isIOSOverride,
    @visibleForTesting bool? isAndroidOverride,
    @visibleForTesting bool enableStartupInitialization = true,
  }) : _isIOSOverride = isIOSOverride,
       _isAndroidOverride = isAndroidOverride {
    if (enableStartupInitialization) {
      unawaited(initialize());
    }
  }

  DeviceInfoPlugin get deviceInfoPlugin => _deviceInfoPlugin;
  bool get _isIOS => _isIOSOverride ?? Platform.isIOS;
  bool get _isAndroid => _isAndroidOverride ?? Platform.isAndroid;

  /// Initialize the device info service
  Future<void> initialize() async {
    LogDev.info('DeviceInfoService initialized');
    try {
      await getAllDeviceInfo();
    } catch (error) {
      LogDev.warning('Error initializing device info: $error');
    }
    if (!_isIOS) return;

    final deviceId = await _getOrCreateIosDeviceToken();
    LogDev.one('deviceId: $deviceId');
  }

  /// Returns the Android SDK version as an integer.
  /// For non-Android devices, it returns null.
  @override
  Future<int?> getAndroidSdkVersion() async {
    if (_isAndroid) {
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      return androidInfo.version.sdkInt;
    }
    return null;
  }

  /// Checks if the device is running Android 13 or higher
  @override
  Future<bool> isAndroid13OrHigher() async {
    final sdkVersion = await getAndroidSdkVersion();
    return sdkVersion != null && sdkVersion > 32;
  }

  @override
  Future<void> getAllDeviceInfo() async {
    final deviceInfo = await _deviceInfoPlugin.deviceInfo;
    LogDev.one('deviceInfo: ${deviceInfo.data}');
  }

  @override
  Future<String> get deviceToken async {
    String deviceId = '';
    try {
      if (_isAndroid) {
        final AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
        deviceId = androidInfo.id;
      } else if (_isIOS) {
        deviceId = await _getOrCreateIosDeviceToken();
      }
    } catch (e) {
      LogDev.warning('Error getting device info: $e');
    }

    if (deviceId.isEmpty && _isIOS) {
      deviceId = _cachedIosDeviceToken ?? const Uuid().v8();
      _cachedIosDeviceToken = deviceId;
    } else if (deviceId.isEmpty) {
      deviceId = const Uuid().v4();
    }

    return deviceId;
  }

  Future<String> _getOrCreateIosDeviceToken() {
    final cachedToken = _cachedIosDeviceToken;
    if (cachedToken != null && cachedToken.isNotEmpty) {
      return Future.value(cachedToken);
    }

    final activeTask = _iosDeviceTokenTask;
    if (activeTask != null) return activeTask;

    late final Future<String> task;
    task = _loadOrCreateIosDeviceToken().whenComplete(() {
      if (identical(_iosDeviceTokenTask, task)) {
        _iosDeviceTokenTask = null;
      }
    });
    _iosDeviceTokenTask = task;
    return task;
  }

  Future<String> _loadOrCreateIosDeviceToken() async {
    final storedDeviceId = await _localStoreService.getString(key: LocalStoreKey.deviceTokenUID);
    if (storedDeviceId.isNotEmpty) {
      _cachedIosDeviceToken = storedDeviceId;
      return storedDeviceId;
    }

    final generatedDeviceId = const Uuid().v8();
    await _localStoreService.setString(key: LocalStoreKey.deviceTokenUID, value: generatedDeviceId);
    _cachedIosDeviceToken = generatedDeviceId;
    return generatedDeviceId;
  }

  @override
  Future<String> get deviceName async {
    final deviceInfo = await _deviceInfoPlugin.deviceInfo;
    return deviceInfo.data['model'] as String;
  }

  @override
  Future<BaseDeviceInfo?> get deviceInfo async {
    return await _deviceInfoPlugin.deviceInfo;
  }
}
