part of '../services.dart';

@LazySingleton(as: IRemoteConfigService)
class FirebaseRemoteConfigService implements IRemoteConfigService {
  late final FirebaseRemoteConfig _remoteConfig;
  final IPackageInfoService _packageInfoService;

  FirebaseRemoteConfigService(this._packageInfoService) {
    _remoteConfig = FirebaseRemoteConfig.instance;
  }

  @override
  Future<void> initialize() async {
    try {
      // Set default values
      await _remoteConfig.setDefaults({
        RemoteConfigKey.latestAndroidVersion: '1.0.0',
        RemoteConfigKey.latestIosVersion: '1.0.0',
        RemoteConfigKey.forceUserUpdate: false,
      });

      // Set config settings
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: Duration.zero,
        ),
      );

      // Fetch and activate
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      LogDev.error('Error initializing Firebase Remote Config: $e');
    }
  }

  @override
  String get latestAndroidVersion => _remoteConfig.getString(RemoteConfigKey.latestAndroidVersion);

  @override
  String get latestIosVersion => _remoteConfig.getString(RemoteConfigKey.latestIosVersion);

  @override
  bool get forceUserUpdate => _remoteConfig.getBool(RemoteConfigKey.forceUserUpdate);

  @override
  AppFunctionEntity get appFunctionModel {
    try {
      final jsonString = _remoteConfig.getString(RemoteConfigKey.appFunction);
      if (jsonString.isEmpty) {
        return AppFunctionEntity();
      }
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return AppFunctionEntity.fromJson(jsonMap);
    } catch (e) {
      LogDev.error('Error parsing AppFunctionModel from Remote Config: $e');
      return AppFunctionEntity();
    }
  }

  @override
  Future<bool> shouldForceUpdate() async {
    try {
      if (!forceUserUpdate) {
        return false;
      }

      final String minVersion = Platform.isAndroid ? latestAndroidVersion : latestIosVersion;

      return _packageInfoService.isVersionLowerThan(minVersion);
    } catch (e) {
      LogDev.error('Error checking app version: $e');
      return false;
    }
  }

  // Method removed in favor of PackageInfoService.isVersionLowerThan
}
