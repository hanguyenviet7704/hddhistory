part of '../../onboarding.dart';

@freezed
abstract class OnboardingBrainConfigModel with _$OnboardingBrainConfigModel {
  const factory OnboardingBrainConfigModel({
    @Default(BaseMultiLanguage()) BaseMultiLanguage heading,
    @Default(BaseMultiLanguage()) BaseMultiLanguage headingHighlight,
    @Default(BaseMultiLanguage()) BaseMultiLanguage headingSuffix,
    @Default(BaseMultiLanguage()) BaseMultiLanguage unlockedPillTemplate,
    @Default(BaseMultiLanguage()) BaseMultiLanguage moreTemplate,
    @Default('') String imageUrl,
  }) = _OnboardingBrainConfigModel;

  factory OnboardingBrainConfigModel.fromJson(Map<String, dynamic> json) => _$OnboardingBrainConfigModelFromJson(json);
}

extension OnboardingBrainConfigModelExtension on OnboardingBrainConfigModel {
  OnboardingBrainConfigEntity toEntity() => OnboardingBrainConfigEntity(
    heading: heading,
    headingHighlight: headingHighlight,
    headingSuffix: headingSuffix,
    unlockedPillTemplate: unlockedPillTemplate,
    moreTemplate: moreTemplate,
    imageUrl: imageUrl,
  );
}
