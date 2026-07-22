part of '../../onboarding.dart';

abstract class IOnboardingRepository {
  /// Fetches the 9-screen onboarding content config. Never surfaces a
  /// [Left] for "no content yet" — falls back to cache, then to a blank
  /// entity that the presentation-layer copy resolvers fill with the
  /// hardcoded EN/VI defaults. See [OnboardingContentConfigEntity].
  TaskEither<AppException, OnboardingContentConfigEntity> getOnboardingConfig();
}
