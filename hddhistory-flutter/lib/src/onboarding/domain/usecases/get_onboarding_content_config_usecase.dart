part of '../../onboarding.dart';

@lazySingleton
class GetOnboardingContentConfigUseCase implements BaseUseCase<Unit, OnboardingContentConfigEntity> {
  final IOnboardingRepository _repository;

  GetOnboardingContentConfigUseCase(this._repository);

  @override
  TaskEither<AppException, OnboardingContentConfigEntity> call(Unit params) {
    return _repository.getOnboardingConfig();
  }
}
