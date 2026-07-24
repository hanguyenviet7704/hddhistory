part of '../services.dart';

abstract interface class IRemoteConfigService {
  AppVersionConfigEntity get appVersionConfig;
  AppFunctionEntity get appFunction;
  CourseConfigEntity get courseConfig;
  OnboardingConfigEntity get onboardingConfig;
  PaywallConfigEntity get paywallConfig;
  Future<void> initialize();
  Future<bool> shouldForceUpdate();

  /// True when a NEWER app version exists but the update is NOT forced — the
  /// signal for the optional-update header banner on Home. The forced case is
  /// handled separately by [shouldForceUpdate] (blocking splash dialog).
  Future<bool> optionalUpdateAvailable();
}
