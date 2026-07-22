part of '../../onboard.dart';

@freezed
abstract class OnboardPathEntity with _$OnboardPathEntity {
  const factory OnboardPathEntity({
    @Default('') String key,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default('') String shortTitle,
    @Default('') String iconKey,
    @Default('') String iconUrl,
    @Default('') String trackingLabel,
    @Default(0) int order,
    @Default([]) List<OnboardSymptomEntity> symptoms,
  }) = _OnboardPathEntity;

  factory OnboardPathEntity.fromJson(Map<String, dynamic> json) => _$OnboardPathEntityFromJson(json);
}
