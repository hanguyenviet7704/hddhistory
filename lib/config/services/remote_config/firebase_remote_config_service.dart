part of '../services.dart';

@lazySingleton
class FirebaseRemoteConfigService {
  late final FirebaseRemoteConfig _remoteConfig;

  final IPackageInfoService _packageInfoService;

  FirebaseRemoteConfigService(this._packageInfoService) {
    _remoteConfig = FirebaseRemoteConfig.instance;
  }

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

  String get latestAndroidVersion => _remoteConfig.getString(RemoteConfigKey.latestAndroidVersion);

  String get latestIosVersion => _remoteConfig.getString(RemoteConfigKey.latestIosVersion);

  bool get forceUserUpdate => _remoteConfig.getBool(RemoteConfigKey.forceUserUpdate);

  String get socialDiscordLink => _remoteConfig.getString(RemoteConfigKey.socialDiscordLink);

  AppFunctionModel get appFunctionModel {
    try {
      final jsonString = _remoteConfig.getString(RemoteConfigKey.appFunction);
      if (jsonString.isEmpty) {
        return AppFunctionModel();
      }
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return AppFunctionModel.fromJson(jsonMap);
    } catch (e) {
      LogDev.error('Error parsing AppFunctionModel from Remote Config: $e');
      return AppFunctionModel();
    }
  }

  List<String> getCurriculums() {
    final raw = _remoteConfig.getString(RemoteConfigKey.curriculum);
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (!data.containsKey("curriculums")) return [];
      final List<String> curriculums = data["curriculums"].map<String>((e) => e.toString()).toList();
      if (curriculums.isEmpty) return [];
      return curriculums;
    } catch (e) {
      LogDev.error('getCurriculums error: $e');
      return [];
    }
  }

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
