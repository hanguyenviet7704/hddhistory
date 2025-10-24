part of '../../exercise.dart';

@freezed
abstract class ExerciseDocumentModel with _$ExerciseDocumentModel {
  const factory ExerciseDocumentModel({
    @Default(0) int id,
    @Default(ExerciseDocumentType.text) ExerciseDocumentType type,
    @Default(DocumentDataModel()) DocumentDataModel data,
  }) = _ExerciseDocumentModel;

  factory ExerciseDocumentModel.fromJson(Map<String, dynamic> json) => _$ExerciseDocumentModelFromJson(json);
}

enum ExerciseDocumentType {
  @JsonValue('text')
  text,
  @JsonValue('video')
  video,
  @JsonValue('image')
  image,
  @JsonValue('audio')
  audio,
}

extension ExerciseDocumentModelExtension on ExerciseDocumentModel {
  ExerciseDocumentEntity toEntity() => ExerciseDocumentEntity(
    id: id,
    type: type,
    data: data.toEntity(),
  );
}
