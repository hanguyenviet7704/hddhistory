part of '../../lesson.dart';

@freezed
abstract class AnswerEntity with _$AnswerEntity {
  const factory AnswerEntity({
    @Default(0) int id,
    @Default('') String correctAnswer,
  }) = _AnswerEntity;

  factory AnswerEntity.fromJson(Map<String, dynamic> json) => _$AnswerEntityFromJson(json);
}

