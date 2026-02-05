part of '../../onboard.dart';

@freezed
abstract class OnboardMotivationEntity with _$OnboardMotivationEntity {
  const factory OnboardMotivationEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage content,
    @Default('') String image,
  }) = _OnboardMotivationEntity;

  factory OnboardMotivationEntity.fromJson(Map<String, dynamic> json) => _$OnboardMotivationEntityFromJson(json);
}
