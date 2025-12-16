part of '../../onboard.dart';

@freezed
abstract class OnboardIntroEntity with _$OnboardIntroEntity {
  const factory OnboardIntroEntity({
    @Default(0) int id,
    @Default('') String image,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage content,
    @Default('') String sourceTitle,
    @Default('') String source,
  }) = _OnboardIntroEntity;

  factory OnboardIntroEntity.fromJson(Map<String, dynamic> json) => _$OnboardIntroEntityFromJson(json);
}
