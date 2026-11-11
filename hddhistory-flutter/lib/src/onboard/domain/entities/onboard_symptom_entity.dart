part of '../../onboard.dart';

@freezed
abstract class OnboardSymptomEntity with _$OnboardSymptomEntity {
  const factory OnboardSymptomEntity({
    @Default('') String key,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default('') String trackingLabel,
    @Default(0) int order,
  }) = _OnboardSymptomEntity;

  factory OnboardSymptomEntity.fromJson(Map<String, dynamic> json) => _$OnboardSymptomEntityFromJson(json);
}
