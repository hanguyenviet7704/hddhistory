part of '../../onboarding.dart';

@lazySingleton
class SubmitOnboardingAnswersUseCase implements BaseUseCase<OnboardingAnswersRequest, OnboardingRecommendationEntity> {
  final IOnboardingRepository _repository;

  SubmitOnboardingAnswersUseCase(this._repository);

  @override
  TaskEither<AppException, OnboardingRecommendationEntity> call(OnboardingAnswersRequest params) {
    return _repository.submitAnswers(params);
  }
}
