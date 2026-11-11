part of '../../onboarding.dart';

/// Content for the Paths screen (screen 5 of 9) — multi-select capped at
/// [OnboardingPathsConfigEntity.maxSelect]. Note there is no `ctaLabel` field
/// on this section in the API contract — the continue button copy is
/// expected to be a local constant on whatever consumes this section.
@freezed
abstract class OnboardingPathsConfigEntity with _$OnboardingPathsConfigEntity {
  const factory OnboardingPathsConfigEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage heading,
    @Default(BaseMultiLanguage()) BaseMultiLanguage headingHighlight,
    @Default(BaseMultiLanguage()) BaseMultiLanguage helper,
    @Default(0) int maxSelect,
    @Default([]) List<OnboardingPathItemEntity> items,
  }) = _OnboardingPathsConfigEntity;
}

@freezed
abstract class OnboardingPathItemEntity with _$OnboardingPathItemEntity {
  const factory OnboardingPathItemEntity({
    @Default('') String key,
    @Default(BaseMultiLanguage()) BaseMultiLanguage label,
    @Default('') String iconKey,
    @Default('') String iconUrl,
    @Default(0) int order,
    @Default([]) List<OnboardingPathSymptomEntity> symptoms,
  }) = _OnboardingPathItemEntity;
}

/// A symptom nested under a path item (screen 5) — `key` must equal an
/// `OnboardingSymptom` enum `trackingId` (see
/// `hddhistory-api/plans/260721-onboard-v2-config-driven/contract.md`).
@freezed
abstract class OnboardingPathSymptomEntity with _$OnboardingPathSymptomEntity {
  const factory OnboardingPathSymptomEntity({
    @Default('') String key,
    @Default(BaseMultiLanguage()) BaseMultiLanguage label,
    @Default(0) int order,
  }) = _OnboardingPathSymptomEntity;
}
