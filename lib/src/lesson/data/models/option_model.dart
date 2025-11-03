part of '../../lesson.dart';

@freezed
abstract class OptionModel with _$OptionModel {
  const factory OptionModel({
    @Default(0) int id,
    @Default('') String text,
    @Default('') String value,
    @Default(false) bool isCorrect,
  }) = _OptionModel;

  factory OptionModel.fromJson(Map<String, dynamic> json) => _$OptionModelFromJson(json);
}

extension OptionModelExtension on OptionModel {
  OptionEntity toEntity() => OptionEntity(
    id: id,
    text: text,
    value: value,
    isCorrect: isCorrect,
  );
}