part of '../../lesson.dart';

@freezed
abstract class ExplanationOptionModel with _$ExplanationOptionModel {
  const factory ExplanationOptionModel({
    @Default(0) int id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage value,
    @Default(BaseMultiLanguage()) BaseMultiLanguage explanation,
  }) = _ExplanationOptionModel;

  factory ExplanationOptionModel.fromJson(Map<String, dynamic> json) =>
      _$ExplanationOptionModelFromJson(json);
}

extension ExplanationOptionModelExtension on ExplanationOptionModel {
  ExplanationOptionEntity toEntity() => ExplanationOptionEntity(
    id: id,
    value: value,
    explanation: explanation,
  );
}
