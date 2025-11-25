part of '../../lesson.dart';

@freezed
abstract class AnswerModel with _$AnswerModel {
  const factory AnswerModel({
    @Default(0) int id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage correctAnswer,
  }) = _AnswerModel;

  factory AnswerModel.fromJson(Map<String, dynamic> json) => _$AnswerModelFromJson(json);
}

extension AnswerModelExtension on AnswerModel {
  AnswerEntity toEntity() => AnswerEntity(
    id: id,
    correctAnswer: correctAnswer,
  );
}
