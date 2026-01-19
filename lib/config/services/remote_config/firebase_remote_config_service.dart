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
        RemoteConfigKey.appVersionConfig: jsonEncode({
          'forceUserUpdate': false,
          'latestAndroidVersion': '1.0.0',
          'latestIosVersion': '1.0.0',
        }),
        RemoteConfigKey.paywallConfig: jsonEncode({
          'enableLessonLock': false,
          'lessonLock': 5,
        }),
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
  AppFunctionEntity get appFunctionModel {
    try {
      final jsonString = _remoteConfig.getString(RemoteConfigKey.appFunction);
      if (jsonString.isEmpty) {
        return AppFunctionEntity();
      }
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return AppFunctionEntity.fromJson(jsonMap);
    } catch (e) {
      LogDev.error('Error parsing AppFunctionEntity from Remote Config: $e');
      return AppFunctionEntity();
    }
  }

  @override
  AppVersionConfigEntity get appVersionConfigModel {
    try {
      final jsonString = _remoteConfig.getString(RemoteConfigKey.appVersionConfig);
      if (jsonString.isEmpty) {
        return AppVersionConfigEntity();
      }
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return AppVersionConfigEntity.fromJson(jsonMap);
    } catch (e) {
      LogDev.error('Error parsing AppVersionConfigEntity from Remote Config: $e');
      return AppVersionConfigEntity();
    }
  }

  @override
  PaywallConfigEntity get paywallConfigModel {
    try {
      final jsonString = _remoteConfig.getString(RemoteConfigKey.paywallConfig);
      if (jsonString.isEmpty) {
        return PaywallConfigEntity();
      }
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return PaywallConfigEntity.fromJson(jsonMap);
    } catch (e) {
      LogDev.error('Error parsing PaywallConfigEntity from Remote Config: $e');
      return PaywallConfigEntity();
    }
  }

  @override
  Future<bool> shouldForceUpdate() async {
    try {
      final config = appVersionConfigModel;
      if (!config.forceUserUpdate) {
        return false;
      }

      if (Platform.isAndroid) {
        if (config.latestAndroidVersion.isEmpty) return false;
        return _packageInfoService.isVersionLowerThan(config.latestAndroidVersion);
      }
      if (Platform.isIOS) {
        if (config.latestIosVersion.isEmpty) return false;
        return _packageInfoService.isVersionLowerThan(config.latestIosVersion);
      }

      return false;
    } catch (e) {
      LogDev.error('Error checking app version: $e');
      return false;
    }
  }

}
