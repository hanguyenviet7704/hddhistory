part of '../../onboard_branching.dart';

@lazySingleton
class GetOnboardingScenarioBranchingUseCase implements UseCaseWithoutParams<OnboardingScenarioBranchingEntity> {
  final IOnboardBranchingRepository _repository;

  GetOnboardingScenarioBranchingUseCase(this._repository);

  @override
  TaskEither<AppException, OnboardingScenarioBranchingEntity> call() {
    return _repository.getOnboardingScenarioBranching();
  }
}

