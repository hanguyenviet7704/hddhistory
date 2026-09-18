part of '../../onboarding.dart';

abstract class IOnboardingRepository {
  /// Fetches the 9-screen onboarding content config. Never surfaces a
  /// [Left] for "no content yet" — falls back to cache, then to a blank
  /// entity that the presentation-layer copy resolvers fill with the
  /// hardcoded EN/VI defaults. See [OnboardingContentConfigEntity].
  TaskEither<AppException, OnboardingContentConfigEntity> getOnboardingConfig();

  /// Fetches the onboarding v3 taxonomy (branches + packages). Unlike
  /// [getOnboardingConfig] there is no bundled fallback content — a failed
  /// fetch falls back to cache, and if there is no cache either this emits
  /// [Left] so the presentation layer can show an error + retry.
  TaskEither<AppException, OnboardingTaxonomyEntity> getTaxonomy();

  /// Submits the onboarding v3 answers and returns the recommended courses.
  TaskEither<AppException, OnboardingRecommendationEntity> submitAnswers(OnboardingAnswersRequest request);
}
