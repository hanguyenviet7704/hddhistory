part of '../../onboarding.dart';

@LazySingleton(as: IOnboardingRepository)
class OnboardingRepository with RestfulRequestHandlerMixin implements IOnboardingRepository {
  final OnboardingApi _api;
  final OnboardingLocalDataSource _localDataSource;

  OnboardingRepository(this._api, this._localDataSource);

  /// Fetches the content config. `onError`/`defaultValue` both resolve to a
  /// non-null value (cache, then a blank entity) so [callApiWithTransform]'s
  /// inner try/catch always succeeds — the outer error-toast branch never
  /// fires and this TaskEither never emits [Left]. That's deliberate: a
  /// failed fetch on a brand-new device (first run, offline, backend not
  /// seeded yet) must render the flow with the bundled EN/VI defaults
  /// silently, not an error screen. See [OnboardingContentConfigEntity].
  @override
  TaskEither<AppException, OnboardingContentConfigEntity> getOnboardingConfig() {
    return callApiWithTransform<OnboardingContentConfigModel, OnboardingContentConfigEntity>(
      apiCall: () => _api.getOnboardingConfig(),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async {
        if (data != null) await _localDataSource.cacheConfig(data);
      },
      onError: () async {
        final cached = await _localDataSource.getCachedConfig();
        if (cached != null) return cached.toEntity();
        return const OnboardingContentConfigEntity();
      },
      defaultValue: const OnboardingContentConfigEntity(),
      enableErrorMessages: false,
    );
  }
}
