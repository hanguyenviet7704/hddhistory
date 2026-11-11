part of '../services.dart';

abstract interface class IRemoteConfigService {
  AppVersionConfigEntity get appVersionConfig;
  AppFunctionEntity get appFunction;
  CourseConfigEntity get courseConfig;
  OnboardingConfigEntity get onboardingConfig;
  PaywallConfigEntity get paywallConfig;
  Future<void> initialize();

  /// True when this build is older than the latest version for its platform AND
  /// [AppVersionConfigEntity.forceUserUpdate] is set — the signal for the
  /// blocking splash dialog.
  ///
  /// The gate lives inside the app, so it only ever protects builds that ship
  /// with this code. Clients already in the wild without it cannot be blocked
  /// retroactively.
  Future<bool> shouldForceUpdate();

  /// True when a NEWER app version exists but the update is NOT forced — the
  /// signal for the optional-update header banner on Home. The forced case is
  /// handled separately by [shouldForceUpdate], so the two are mutually
  /// exclusive and a forced update never also surfaces the banner.
  Future<bool> optionalUpdateAvailable();
}
