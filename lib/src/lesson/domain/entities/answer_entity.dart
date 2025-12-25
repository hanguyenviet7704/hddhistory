part of '../../lesson.dart';

@freezed
abstract class AnswerEntity with _$AnswerEntity {
  const factory AnswerEntity({
    @Default(0) int id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage correctAnswer,
    @Default('') String record,
    @Default('') String review,
  }) = _AnswerEntity;

  factory AnswerEntity.fromJson(Map<String, dynamic> json) => _$AnswerEntityFromJson(json);
}

