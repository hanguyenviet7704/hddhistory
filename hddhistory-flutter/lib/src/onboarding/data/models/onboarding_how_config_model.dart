part of '../../onboarding.dart';

@freezed
abstract class OnboardingHowConfigModel with _$OnboardingHowConfigModel {
  const factory OnboardingHowConfigModel({
    @Default(BaseMultiLanguage()) BaseMultiLanguage eyebrow,
    @Default(BaseMultiLanguage()) BaseMultiLanguage heading,
    @Default(BaseMultiLanguage()) BaseMultiLanguage headingHighlight,
    @Default([]) List<OnboardingHowStepModel> steps,
    @Default(BaseMultiLanguage()) BaseMultiLanguage footer,
    @Default(BaseMultiLanguage()) BaseMultiLanguage ctaLabel,
  }) = _OnboardingHowConfigModel;

  factory OnboardingHowConfigModel.fromJson(Map<String, dynamic> json) => _$OnboardingHowConfigModelFromJson(json);
}

extension OnboardingHowConfigModelExtension on OnboardingHowConfigModel {
  OnboardingHowConfigEntity toEntity() => OnboardingHowConfigEntity(
    eyebrow: eyebrow,
    heading: heading,
    headingHighlight: headingHighlight,
    steps: steps.map((step) => step.toEntity()).toList(),
    footer: footer,
    ctaLabel: ctaLabel,
  );
}

@freezed
abstract class OnboardingHowStepModel with _$OnboardingHowStepModel {
  const factory OnboardingHowStepModel({
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage body,
  }) = _OnboardingHowStepModel;

  factory OnboardingHowStepModel.fromJson(Map<String, dynamic> json) => _$OnboardingHowStepModelFromJson(json);
}

extension OnboardingHowStepModelExtension on OnboardingHowStepModel {
  OnboardingHowStepEntity toEntity() => OnboardingHowStepEntity(title: title, body: body);
}
