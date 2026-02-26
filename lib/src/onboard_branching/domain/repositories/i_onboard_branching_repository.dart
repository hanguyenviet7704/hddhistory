part of '../../onboard_branching.dart';

abstract class IOnboardBranchingRepository {
  TaskEither<AppException, OnboardingScenarioBranchingEntity> getOnboardingScenarioBranching();
}
