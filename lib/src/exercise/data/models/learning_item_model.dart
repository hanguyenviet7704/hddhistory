part of '../../exercise.dart';

@freezed
abstract class LearningItemModel with _$LearningItemModel {
  const factory LearningItemModel({
    @Default('') String id,
    @Default(AppUser()) AppUser createdBy,
    @Default(AppUser()) AppUser updatedBy,
    @Default('') String keypointId,
    @Default(BaseMultiLanguage(en: '')) BaseMultiLanguage title,
    @Default('') String image,
    @Default('') String type,
    @Default([]) List<QuestionModel> questions,
    // @Default() List<SubQuestionModel> subQuestions,
    // @Default() List<DocumentModel> documents,
    // @Default() List<TagModel> tag,
    @Default(0) int index,
    @Default(false) bool isSub,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _LearningItemModel;

  factory LearningItemModel.fromJson(Map<String, dynamic> json) => _$LearningItemModelFromJson(json);
}

extension LearningItemModelExtension on LearningItemModel {
  LearningItemEntity toEntity() => LearningItemEntity(
    id: id,
    createdBy: createdBy,
    updatedBy: updatedBy,
    keypointId: keypointId,
    title: title,
    image: image,
    type: type,
    questions: questions.map((model) => model.toEntity()).toList(),
    index: index,
    isSub: isSub,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
