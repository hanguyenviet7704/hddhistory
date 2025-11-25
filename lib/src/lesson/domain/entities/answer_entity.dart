part of '../../lesson.dart';

@freezed
abstract class AnswerEntity with _$AnswerEntity {
  const factory AnswerEntity({
    @Default(0) int id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage correctAnswer,
  }) = _AnswerEntity;

  factory AnswerEntity.fromJson(Map<String, dynamic> json) => _$AnswerEntityFromJson(json);
}

