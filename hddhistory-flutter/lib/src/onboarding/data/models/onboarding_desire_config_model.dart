part of '../../onboarding.dart';

@freezed
abstract class OnboardingDesireConfigModel with _$OnboardingDesireConfigModel {
  const factory OnboardingDesireConfigModel({
    @Default(BaseMultiLanguage()) BaseMultiLanguage heading,
    @Default(BaseMultiLanguage()) BaseMultiLanguage headingHighlight,
    @Default(BaseMultiLanguage()) BaseMultiLanguage helper,
  }) = _OnboardingDesireConfigModel;

  factory OnboardingDesireConfigModel.fromJson(Map<String, dynamic> json) => _$OnboardingDesireConfigModelFromJson(json);
}

extension OnboardingDesireConfigModelExtension on OnboardingDesireConfigModel {
  OnboardingDesireConfigEntity toEntity() => OnboardingDesireConfigEntity(
    heading: heading,
    headingHighlight: headingHighlight,
    helper: helper,
  );
}
