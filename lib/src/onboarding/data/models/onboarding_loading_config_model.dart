part of '../../onboarding.dart';

@freezed
abstract class OnboardingLoadingConfigModel with _$OnboardingLoadingConfigModel {
  const factory OnboardingLoadingConfigModel({
    @Default(BaseMultiLanguage()) BaseMultiLanguage heading,
    @Default(BaseMultiLanguage()) BaseMultiLanguage headingHighlight,
    @Default([]) List<BaseMultiLanguage> lines,
  }) = _OnboardingLoadingConfigModel;

  factory OnboardingLoadingConfigModel.fromJson(Map<String, dynamic> json) => _$OnboardingLoadingConfigModelFromJson(json);
}

extension OnboardingLoadingConfigModelExtension on OnboardingLoadingConfigModel {
  OnboardingLoadingConfigEntity toEntity() =>
      OnboardingLoadingConfigEntity(heading: heading, headingHighlight: headingHighlight, lines: lines);
}
