part of '../../video_lesson.dart';

@freezed
abstract class VideoQuestionModel with _$VideoQuestionModel {
  const factory VideoQuestionModel({
    @Default(0) int atSecond,
    @Default(QuestionModel()) QuestionModel exercise,
  }) = _VideoQuestionModel;

  factory VideoQuestionModel.fromJson(Map<String, dynamic> json) => _$VideoQuestionModelFromJson(json);
}

extension VideoQuestionModelExtension on VideoQuestionModel {
  VideoQuestionEntity toEntity() => VideoQuestionEntity(
    atSecond: atSecond,
    exercise: exercise.toEntity(),
  );
}
