part of '../services.dart';

abstract interface class IDeviceInfoService {
  Future<String> get deviceToken;
  Future<String> get deviceName;
  Future<void> getAllDeviceInfo();
  Future<int?> getAndroidSdkVersion();
  Future<bool> isAndroid13OrHigher();
  Future<BaseDeviceInfo?> get deviceInfo;
}


@lazySingleton
class DeviceInfoService implements IDeviceInfoService {
  final DeviceInfoPlugin _deviceInfoPlugin;

  DeviceInfoService() : _deviceInfoPlugin = DeviceInfoPlugin();

  DeviceInfoPlugin get deviceInfoPlugin => _deviceInfoPlugin;

  /// Initialize the device info service
  Future<void> initialize() async {
    LogDev.info('DeviceInfoService initialized');
    await getAllDeviceInfo();
  }

  /// Returns the Android SDK version as an integer.
  /// For non-Android devices, it returns null.
  @override
  Future<int?> getAndroidSdkVersion() async {
    if (Platform.isAndroid) {
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
    LogDev.one('deviceInfo: ${deviceInfo.toMap()}');
  }

  @override
  Future<String> get deviceToken async {
    // String deviceIdFromLocalStore = await LocalStoreService.instance.getString(key: LocalStoreKey.deviceTokenUID);
    String deviceIdFromLocalStore = '';
    if (deviceIdFromLocalStore.isNotEmpty) {
      return deviceIdFromLocalStore;
    }

    String deviceId = '';
    try {
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
        deviceId = androidInfo.id; // This is a unique ID on Android
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await _deviceInfoPlugin.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? ''; // Unique ID on iOS
      }
    } catch (e) {
      LogDev.warning('Error getting device info: $e');
    }

    // If we couldn't get a device ID, generate a UUID
    if (deviceId.isEmpty) {
      deviceId = const Uuid().v8();
      // await LocalStoreService.setString(key: LocalStoreKey.deviceTokenUID, value: deviceId);
      // You might want to store this generated UUID persistently
      // so it remains consistent across app launches
    }

    return deviceId;
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
