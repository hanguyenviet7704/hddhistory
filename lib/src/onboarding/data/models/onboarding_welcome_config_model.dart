part of '../../onboarding.dart';

@freezed
abstract class OnboardingWelcomeConfigModel with _$OnboardingWelcomeConfigModel {
  const factory OnboardingWelcomeConfigModel({
    @Default(BaseMultiLanguage()) BaseMultiLanguage titlePrefix,
    @Default('') String titleBrand,
    @Default(BaseMultiLanguage()) BaseMultiLanguage subtitle,
    @Default(BaseMultiLanguage()) BaseMultiLanguage ctaLabel,
    @Default([]) List<OnboardingWelcomeDeckItemModel> deck,
  }) = _OnboardingWelcomeConfigModel;

  factory OnboardingWelcomeConfigModel.fromJson(Map<String, dynamic> json) => _$OnboardingWelcomeConfigModelFromJson(json);
}

extension OnboardingWelcomeConfigModelExtension on OnboardingWelcomeConfigModel {
  OnboardingWelcomeConfigEntity toEntity() => OnboardingWelcomeConfigEntity(
    titlePrefix: titlePrefix,
    titleBrand: titleBrand,
    subtitle: subtitle,
    ctaLabel: ctaLabel,
    deck: deck.map((item) => item.toEntity()).toList(),
  );
}

@freezed
abstract class OnboardingWelcomeDeckItemModel with _$OnboardingWelcomeDeckItemModel {
  const factory OnboardingWelcomeDeckItemModel({
    @Default('') String key,
    @Default(BaseMultiLanguage()) BaseMultiLanguage label,
    @Default('') String imageUrl,
    @Default(0) int order,
  }) = _OnboardingWelcomeDeckItemModel;

  factory OnboardingWelcomeDeckItemModel.fromJson(Map<String, dynamic> json) => _$OnboardingWelcomeDeckItemModelFromJson(json);
}

extension OnboardingWelcomeDeckItemModelExtension on OnboardingWelcomeDeckItemModel {
  // NOTE: `order` must be qualified with `this.` here — `package:injectable`
  // exports a top-level `const order = Order(0);` that otherwise shadows the
  // instance getter inside this extension body (see onboard_path_model.dart
  // for the same gotcha).
  OnboardingWelcomeDeckItemEntity toEntity() => OnboardingWelcomeDeckItemEntity(
    key: key,
    label: label,
    imageUrl: imageUrl,
    order: this.order,
  );
}
