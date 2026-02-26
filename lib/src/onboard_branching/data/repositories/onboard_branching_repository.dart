part of '../../onboard_branching.dart';

@LazySingleton(as: IOnboardBranchingRepository)
class OnboardBranchingRepository with RestfulRequestHandlerMixin implements IOnboardBranchingRepository {
  final OnboardBranchingApi _api;
  final OnboardBranchingLocalDataSource _localDataSource;

  OnboardBranchingRepository(
    this._api,
    this._localDataSource,
  );

  @override
  TaskEither<AppException, OnboardingScenarioBranchingEntity> getOnboardingScenarioBranching(String id) {
    return callApiWithTransform<OnboardingScenarioBranchingModel, OnboardingScenarioBranchingEntity>(
      apiCall: () => _api.getOnboardingScenarioBranching(id),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheOnboardingScenarioBranching(id, data ?? OnboardingScenarioBranchingModel()),
      onError: () async {
        final cachedModel = await _localDataSource.getCachedOnboardingScenarioBranching(id);
        return cachedModel?.toEntity();
      },
      defaultValue: OnboardingScenarioBranchingEntity(),
    );
  }
}
