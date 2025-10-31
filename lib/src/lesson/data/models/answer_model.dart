part of '../../lesson.dart';

@freezed
abstract class AnswerModel with _$AnswerModel {
  const factory AnswerModel({
    @Default('') String correctAnswer,
    @Default(0) int id,
  }) = _AnswerModel;

  factory AnswerModel.fromJson(Map<String, dynamic> json) => _$AnswerModelFromJson(json);
}

extension AnswerModelExtension on AnswerModel {
  AnswerEntity toEntity() => AnswerEntity(
    id: id,
    correctAnswer: correctAnswer,
  );
}
