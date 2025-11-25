part of '../../lesson.dart';

@freezed
abstract class OptionEntity with _$OptionEntity {
  const factory OptionEntity({
    @Default(0) int id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage text,
    @Default(BaseMultiLanguage()) BaseMultiLanguage value,
    @Default(false) bool isCorrect,
  }) = _OptionEntity;

  factory OptionEntity.fromJson(Map<String, dynamic> json) => _$OptionEntityFromJson(json);
}
