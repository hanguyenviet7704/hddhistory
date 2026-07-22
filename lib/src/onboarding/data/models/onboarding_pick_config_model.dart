part of '../../onboarding.dart';

@freezed
abstract class OnboardingPickConfigModel with _$OnboardingPickConfigModel {
  const factory OnboardingPickConfigModel({
    @Default(BaseMultiLanguage()) BaseMultiLanguage eyebrow,
    @Default(BaseMultiLanguage()) BaseMultiLanguage heading,
    @Default(BaseMultiLanguage()) BaseMultiLanguage headingHighlight,
    @Default(BaseMultiLanguage()) BaseMultiLanguage label,
    @Default(BaseMultiLanguage()) BaseMultiLanguage primaryCta,
    @Default(BaseMultiLanguage()) BaseMultiLanguage secondaryCta,
    @Default('') String iconUrl,
  }) = _OnboardingPickConfigModel;

  factory OnboardingPickConfigModel.fromJson(Map<String, dynamic> json) => _$OnboardingPickConfigModelFromJson(json);
}

extension OnboardingPickConfigModelExtension on OnboardingPickConfigModel {
  OnboardingPickConfigEntity toEntity() => OnboardingPickConfigEntity(
    eyebrow: eyebrow,
    heading: heading,
    headingHighlight: headingHighlight,
    label: label,
    primaryCta: primaryCta,
    secondaryCta: secondaryCta,
    iconUrl: iconUrl,
  );
}
