part of '../services.dart';

@LazySingleton(as: IRemoteConfigService)
class FirebaseRemoteConfigService implements IRemoteConfigService {
  static const Duration _fetchTimeout = Duration(seconds: 10);
  // Serve cached config instantly and only refetch after this interval, instead
  // of forcing a live network fetch on EVERY launch (Duration.zero) — that was
  // making the splash wait on a Remote Config round-trip each cold start.
  // Config still refreshes in the background at least this often, and the
  // force-update gate is additionally capped by a timeout in SplashPage.
  static const Duration _minimumFetchInterval = Duration(minutes: 30);

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
          minimumFetchInterval: _minimumFetchInterval,
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
      return shouldBlockForForcedUpdate(
        appVersionConfig,
        isIOS: Platform.isIOS,
        isInstalledOlderThan: _packageInfoService.isVersionLowerThan,
      );
    } catch (e) {
      LogDev.error('shouldForceUpdate: $e');
      return false;
    }
  }

  @override
  Future<bool> optionalUpdateAvailable() async {
    try {
      await _waitForStartupFetch();
      return shouldShowUpdateBanner(
        appVersionConfig,
        isIOS: Platform.isIOS,
        isInstalledOlderThan: _packageInfoService.isVersionLowerThan,
      );
    } catch (e) {
      LogDev.error('optionalUpdateAvailable: $e');
      return false;
    }
  }
}

/// Whether the splash must block entry until the user updates, kept pure so the
/// branching is unit-testable (the platform check and the version comparison are
/// injected).
///
/// Named differently from the `shouldForceUpdate` method that calls it: a
/// top-level function sharing a method's name would be shadowed by that method
/// inside the class, turning the delegation into infinite recursion.
@visibleForTesting
bool shouldBlockForForcedUpdate(
  AppVersionConfigEntity config, {
  required bool isIOS,
  required bool Function(String latestVersion) isInstalledOlderThan,
}) {
  if (!config.forceUserUpdate) return false;
  return _isOlderThanLatest(config, isIOS: isIOS, isInstalledOlderThan: isInstalledOlderThan);
}

/// Whether Home should surface the optional-update banner, kept pure for the
/// same reason.
///
/// Returns false when [AppVersionConfigEntity.forceUserUpdate] is set: that case
/// belongs to the blocking splash dialog, and showing both would stack two
/// update surfaces on the same launch.
@visibleForTesting
bool shouldShowUpdateBanner(
  AppVersionConfigEntity config, {
  required bool isIOS,
  required bool Function(String latestVersion) isInstalledOlderThan,
}) {
  if (config.forceUserUpdate) return false;
  return _isOlderThanLatest(config, isIOS: isIOS, isInstalledOlderThan: isInstalledOlderThan);
}

/// An empty version means "no ceiling published for this platform", which must
/// never be read as "everyone is out of date".
bool _isOlderThanLatest(
  AppVersionConfigEntity config, {
  required bool isIOS,
  required bool Function(String latestVersion) isInstalledOlderThan,
}) {
  final latestVersion = isIOS ? config.latestIosVersion : config.latestAndroidVersion;
  if (latestVersion.trim().isEmpty) return false;
  return isInstalledOlderThan(latestVersion);
}
