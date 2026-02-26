part of '../../onboard_branching.dart';

@lazySingleton
class GetOnboardingScenarioBranchingUseCase implements UseCaseWithParams<String, OnboardingScenarioBranchingEntity> {
  final IOnboardBranchingRepository _repository;

  GetOnboardingScenarioBranchingUseCase(this._repository);

  @override
  TaskEither<AppException, OnboardingScenarioBranchingEntity> call(String params) {
    return _repository.getOnboardingScenarioBranching(params);
  }
}

