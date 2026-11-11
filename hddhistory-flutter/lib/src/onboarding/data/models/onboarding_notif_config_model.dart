part of '../../onboarding.dart';

@freezed
abstract class OnboardingNotifConfigModel with _$OnboardingNotifConfigModel {
  const factory OnboardingNotifConfigModel({
    @Default(BaseMultiLanguage()) BaseMultiLanguage heading,
    @Default(BaseMultiLanguage()) BaseMultiLanguage headingHighlight,
    @Default(BaseMultiLanguage()) BaseMultiLanguage subtitle,
    @Default(BaseMultiLanguage()) BaseMultiLanguage cardTitle,
    @Default(BaseMultiLanguage()) BaseMultiLanguage cardBody,
    @Default(BaseMultiLanguage()) BaseMultiLanguage cardTimestamp,
    @Default(BaseMultiLanguage()) BaseMultiLanguage ctaLabel,
    @Default('') String iconUrl,
  }) = _OnboardingNotifConfigModel;

  factory OnboardingNotifConfigModel.fromJson(Map<String, dynamic> json) => _$OnboardingNotifConfigModelFromJson(json);
}

extension OnboardingNotifConfigModelExtension on OnboardingNotifConfigModel {
  OnboardingNotifConfigEntity toEntity() => OnboardingNotifConfigEntity(
    heading: heading,
    headingHighlight: headingHighlight,
    subtitle: subtitle,
    cardTitle: cardTitle,
    cardBody: cardBody,
    cardTimestamp: cardTimestamp,
    ctaLabel: ctaLabel,
    iconUrl: iconUrl,
  );
}
