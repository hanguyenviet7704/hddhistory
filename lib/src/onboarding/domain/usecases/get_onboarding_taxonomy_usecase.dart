part of '../../onboarding.dart';

@lazySingleton
class GetOnboardingTaxonomyUseCase implements BaseUseCase<Unit, OnboardingTaxonomyEntity> {
  final IOnboardingRepository _repository;

  GetOnboardingTaxonomyUseCase(this._repository);

  @override
  TaskEither<AppException, OnboardingTaxonomyEntity> call(Unit params) {
    return _repository.getTaxonomy();
  }
}
