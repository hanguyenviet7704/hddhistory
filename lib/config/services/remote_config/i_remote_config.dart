part of '../services.dart';

abstract interface class IRemoteConfigService {
  AppVersionConfigEntity get appVersionConfig;
  AppFunctionEntity get appFunction;
  CourseConfigEntity get courseConfig;
  OnboardingConfigEntity get onboardingConfig;
  PaywallConfigEntity get paywallConfig;
  Future<void> initialize();

  /// True when a NEWER app version exists for this platform — the signal for the
  /// update header banner on Home, which is the app's ONLY update surface.
  ///
  /// Deliberately ignores [AppVersionConfigEntity.forceUserUpdate]: the blocking
  /// splash dialog was removed so the banner shows either way. That flag is
  /// therefore no longer enforced anywhere — setting it in Remote Config does
  /// NOT gate old clients.
  Future<bool> updateAvailable();
}
