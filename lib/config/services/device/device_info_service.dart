part of '../services.dart';

@lazySingleton
class DeviceInfoService {
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
  Future<int?> getAndroidSdkVersion() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      return androidInfo.version.sdkInt;
    }
    return null;
  }

  /// Checks if the device is running Android 13 or higher
  Future<bool> isAndroid13OrHigher() async {
    final sdkVersion = await getAndroidSdkVersion();
    return sdkVersion != null && sdkVersion > 32;
  }

  Future<void> getAllDeviceInfo() async {
    final deviceInfo = await _deviceInfoPlugin.deviceInfo;
    LogDev.one('deviceInfo: ${deviceInfo.data}');
  }

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

  // Static helper methods for backward compatibility with existing code
  static Future<int?> getAndroidSdkVersionStatic() async {
    return await AppDI.injector.get<DeviceInfoService>().getAndroidSdkVersion();
  }

  static Future<bool> isAndroid13OrHigherStatic() async {
    return await AppDI.injector.get<DeviceInfoService>().isAndroid13OrHigher();
  }

  static Future<void> getAllDeviceInfoStatic() async {
    return await AppDI.injector.get<DeviceInfoService>().getAllDeviceInfo();
  }

  static Future<String> get deviceTokenStatic async {
    return await AppDI.injector.get<DeviceInfoService>().deviceToken;
  }

  // Static initialize method for backward compatibility
  static void init() {
    AppDI.injector.get<DeviceInfoService>().initialize();
  }
}
