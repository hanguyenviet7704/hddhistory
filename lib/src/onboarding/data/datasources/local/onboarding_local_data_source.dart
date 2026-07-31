part of '../../../onboarding.dart';

/// Local cache for the (singleton) onboarding content config — used as the
/// offline fallback when the config fetch fails after having succeeded at
/// least once before. See [OnboardingRepository.getOnboardingConfig].
abstract class OnboardingLocalDataSource {
  Future<OnboardingContentConfigModel?> getCachedConfig();
  Future<void> cacheConfig(OnboardingContentConfigModel model);
}

@LazySingleton(as: OnboardingLocalDataSource)
class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
  static const String _cacheKey = 'onboarding_content_config_cache';

  final ILocalStoreService _localStoreService;

  OnboardingLocalDataSourceImpl(this._localStoreService);

  @override
  Future<OnboardingContentConfigModel?> getCachedConfig() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheKey);
      if (data.isEmpty) return null;
      return OnboardingContentConfigModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheConfig(OnboardingContentConfigModel model) async {
    try {
      await _localStoreService.setMap(key: _cacheKey, value: model.toJson());
    } catch (e) {
      // Best-effort cache — a failure here should never block onboarding.
    }
  }
}
