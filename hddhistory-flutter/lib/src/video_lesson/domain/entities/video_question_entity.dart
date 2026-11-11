part of '../../video_lesson.dart';

@freezed
abstract class VideoQuestionEntity with _$VideoQuestionEntity {
  const factory VideoQuestionEntity({
    @Default(0) int atSecond,
    @Default(QuestionEntity()) QuestionEntity exercise,
  }) = _VideoQuestionEntity;

  factory VideoQuestionEntity.fromJson(Map<String, dynamic> json) => _$VideoQuestionEntityFromJson(json);
}
