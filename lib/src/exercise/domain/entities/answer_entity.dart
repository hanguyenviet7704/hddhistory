part of '../../exercise.dart';

@freezed
abstract class AnswerEntity with _$AnswerEntity {
  const factory AnswerEntity({
    @Default('') String correctAnswer,
    @Default(0) int id,
  }) = _AnswerEntity;

  factory AnswerEntity.fromJson(Map<String, dynamic> json) => _$AnswerEntityFromJson(json);
}

