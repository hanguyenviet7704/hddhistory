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
  TaskEither<AppException, OnboardingScenarioBranchingEntity> getOnboardingScenarioBranching() {
    return callApiWithTransform<OnboardingScenarioBranchingModel, OnboardingScenarioBranchingEntity>(
      apiCall: () => _api.getOnboardingScenarioBranching(),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async {
        if (data != null) {
          await _localDataSource.cacheOnboardingScenarioBranching(data);
        }
      },
      onError: () async {
        final cachedModel = await _localDataSource.getCachedOnboardingScenarioBranching();
        if (cachedModel != null) {
          return cachedModel.toEntity();
        }
        return null;
      },
      defaultValue: OnboardingScenarioBranchingEntity(),
    );
  }
}
