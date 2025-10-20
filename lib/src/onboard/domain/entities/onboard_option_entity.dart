part of '../../onboard.dart';

@freezed
abstract class OnboardOptionEntity with _$OnboardOptionEntity {
  const factory OnboardOptionEntity({
    @Default(0) int id,
    @Default('') String icon,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage label,
  }) = _OnboardOptionEntity;

  factory OnboardOptionEntity.fromJson(Map<String, dynamic> json) => _$OnboardOptionEntityFromJson(json);
}
