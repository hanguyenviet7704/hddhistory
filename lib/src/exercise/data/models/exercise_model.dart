part of '../../exercise.dart';

@freezed
abstract class ExerciseModel with _$ExerciseModel {
  const factory ExerciseModel({
    String id,
    AppUser createdBy,
    AppUser updatedBy,
    String keypointId,
    BaseMultiLanguage title,
    String image,
    String type,
    List<QuestionModel> questions,
    // List<SubQuestionModel> subQuestions,
    // List<DocumentModel> documents,
    // List<TagModel> tag,
    int index,
    bool isSub,
    DateTime createdAt,
    DateTime updatedAt,
  }) = _ExerciseModel;

  factory ExerciseModel.fromJson(Map<String, dynamic> json) => _$ExerciseModelFromJson(json);
}

extension ExerciseModelExtension on ExerciseModel {
  ExerciseEntity toEntity() => ExerciseEntity(
    id: id,
    createdBy: createdBy,
    updatedBy: updatedBy,
    keypointId: keypointId,
    title: title,
    image: image,
    type: type,
    questions: questions,
    subQuestions: subQuestions,
    documents: documents,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
