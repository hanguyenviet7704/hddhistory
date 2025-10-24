part of '../../exercise.dart';

@freezed
abstract class ExerciseDocumentModel with _$ExerciseDocumentModel {
  const factory ExerciseDocumentModel({
    @Default(0) int id,
    @Default('') String type,
    @Default(DocumentDataModel()) DocumentDataModel data,
  }) = _ExerciseDocumentModel;

  factory ExerciseDocumentModel.fromJson(Map<String, dynamic> json) => _$ExerciseDocumentModelFromJson(json);
}

extension ExerciseDocumentModelExtension on ExerciseDocumentModel {
  ExerciseDocumentEntity toEntity() => ExerciseDocumentEntity(
    id: id,
    type: type,
    data: data.toEntity(),
  );
}
