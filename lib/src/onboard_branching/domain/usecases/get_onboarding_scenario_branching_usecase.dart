part of '../../onboard_branching.dart';

@lazySingleton
class GetOnboardingScenarioBranchingUseCase implements BaseUseCase<Unit, OnboardingScenarioBranchingEntity> {
  final IOnboardBranchingRepository _repository;

  GetOnboardingScenarioBranchingUseCase(this._repository);

  @override
  TaskEither<AppException, OnboardingScenarioBranchingEntity> call(Unit _) {
    return _repository.getOnboardingScenarioBranching();
  }
}
