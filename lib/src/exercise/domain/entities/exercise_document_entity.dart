part of '../../exercise.dart';

@freezed
abstract class ExerciseDocumentEntity with _$ExerciseDocumentEntity {
  const factory ExerciseDocumentEntity({
    @Default(0) int id,
    @Default(ExerciseDocumentType.text) ExerciseDocumentType type,
    @Default(DocumentDataEntity()) DocumentDataEntity data,
  }) = _ExerciseDocumentEntity;

  factory ExerciseDocumentEntity.fromJson(Map<String, dynamic> json) => _$ExerciseDocumentEntityFromJson(json);
}

