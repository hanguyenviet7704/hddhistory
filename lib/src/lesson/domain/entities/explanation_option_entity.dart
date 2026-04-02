part of '../../lesson.dart';

@freezed
abstract class ExplanationOptionEntity with _$ExplanationOptionEntity {
  const factory ExplanationOptionEntity({
    @Default(0) int id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage value,
    @Default(BaseMultiLanguage()) BaseMultiLanguage explanation,
  }) = _ExplanationOptionEntity;

  factory ExplanationOptionEntity.fromJson(Map<String, dynamic> json) =>
      _$ExplanationOptionEntityFromJson(json);
}
