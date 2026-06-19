part of '../services.dart';

@LazySingleton(as: IRemoteConfigService)
class FirebaseRemoteConfigService implements IRemoteConfigService {
  static const Duration _fetchTimeout = Duration(seconds: 10);

  late final FirebaseRemoteConfig _remoteConfig;
  final IPackageInfoService _packageInfoService;
  Future<void>? _initializeFuture;
  Future<bool>? _fetchAndActivateFuture;

  FirebaseRemoteConfigService(this._packageInfoService) {
    _remoteConfig = FirebaseRemoteConfig.instance;
  }

  @override
  Future<void> initialize() {
    return _initializeFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Set default values
      await _remoteConfig.setDefaults({
        RemoteConfigKey.appVersionConfig: jsonEncode({
          'forceUserUpdate': false,
          'latestAndroidVersion': '1.0.0',
          'latestIosVersion': '1.0.0',
        }),
        RemoteConfigKey.courseConfig: jsonEncode({
          'enable': true,
          'finishOptionalKp': true,
        }),
        RemoteConfigKey.onboardingConfig: jsonEncode({
          'enable': true,
          'flowType': OnboardingFlowType.normal.name,
        }),
        RemoteConfigKey.paywallConfig: jsonEncode({
          'enableLessonLock': false,
          'lessonLock': 5,
        }),
      });

      // Set config settings
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: _fetchTimeout,
          minimumFetchInterval: Duration.zero,
        ),
      );

      _fetchAndActivateFuture = _fetchAndActivate();
    } catch (e) {
      LogDev.error('Error initializing Firebase Remote Config: $e');
    }
  }

  Future<bool> _fetchAndActivate() async {
    try {
      return await _remoteConfig.fetchAndActivate();
    } catch (e) {
      LogDev.error('Error fetching Firebase Remote Config: $e');
      return false;
    }
  }

  Future<void> _waitForStartupFetch() async {
    await initialize();
    final fetchAndActivateFuture = _fetchAndActivateFuture;
    if (fetchAndActivateFuture == null) return;

    await fetchAndActivateFuture;
  }

  @override
  AppFunctionEntity get appFunction {
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
  CourseConfigEntity get courseConfig {
    try {
      final jsonString = _remoteConfig.getString(RemoteConfigKey.courseConfig);
      if (jsonString.isEmpty) {
        return CourseConfigEntity();
      }
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return CourseConfigEntity.fromJson(jsonMap);
    } catch (e) {
      LogDev.error('Error parsing CourseConfigEntity from Remote Config: $e');
      return CourseConfigEntity();
    }
  }

  @override
  OnboardingConfigEntity get onboardingConfig {
    try {
      final jsonString = _remoteConfig.getString(RemoteConfigKey.onboardingConfig);
      return OnboardingConfigEntity.fromRawConfig(jsonString);
    } catch (e) {
      LogDev.error('Error parsing OnboardingConfigEntity from Remote Config: $e');
      return const OnboardingConfigEntity();
    }
  }

  @override
  AppVersionConfigEntity get appVersionConfig {
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
  PaywallConfigEntity get paywallConfig {
    try {
      final jsonString = _remoteConfig.getString(RemoteConfigKey.paywallConfig);
      return PaywallConfigEntity.fromRawConfig(jsonString);
    } catch (e) {
      LogDev.error('Error parsing PaywallConfigEntity from Remote Config: $e');
      return PaywallConfigEntity();
    }
  }

  @override
  Future<bool> shouldForceUpdate() async {
    try {
      await _waitForStartupFetch();
      final config = appVersionConfig;
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
