part of '../../onboarding.dart';

@freezed
abstract class OnboardingNameConfigModel with _$OnboardingNameConfigModel {
  const factory OnboardingNameConfigModel({
    @Default(BaseMultiLanguage()) BaseMultiLanguage heading,
    @Default(BaseMultiLanguage()) BaseMultiLanguage headingHighlight,
    @Default(BaseMultiLanguage()) BaseMultiLanguage helper,
    @Default(BaseMultiLanguage()) BaseMultiLanguage inputHint,
    @Default(BaseMultiLanguage()) BaseMultiLanguage ctaLabel,
    @Default('') String iconUrl,
  }) = _OnboardingNameConfigModel;

  factory OnboardingNameConfigModel.fromJson(Map<String, dynamic> json) => _$OnboardingNameConfigModelFromJson(json);
}

extension OnboardingNameConfigModelExtension on OnboardingNameConfigModel {
  OnboardingNameConfigEntity toEntity() => OnboardingNameConfigEntity(
    heading: heading,
    headingHighlight: headingHighlight,
    helper: helper,
    inputHint: inputHint,
    ctaLabel: ctaLabel,
    iconUrl: iconUrl,
  );
}
