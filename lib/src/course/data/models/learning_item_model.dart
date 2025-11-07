part of '../../../course/course.dart';

@freezed
abstract class LearningItemModel with _$LearningItemModel {
  const factory LearningItemModel({
    @Default('') @JsonKey(name: '_id') String id,
    @Default(AppUser()) AppUser createdBy,
    @Default(AppUser()) AppUser updatedBy,
    @Default('') String keypointId,
    @Default(BaseMultiLanguage(en: '')) BaseMultiLanguage title,
    @Default('') String image,
    @Default(LearningItemType.theory) LearningItemType type,
    @Default([]) List<QuestionModel> questions,
    @Default([]) List<QuestionModel> subQuestions,
    @Default([]) List<DocumentModel> documents,
    @Default([]) List<SectionModel> sections,
    @Default([]) List<String> tag,
    @Default(0) int index,
    @Default(false) bool isSub,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _LearningItemModel;

  factory LearningItemModel.fromJson(Map<String, dynamic> json) => _$LearningItemModelFromJson(json);
}

enum LearningItemType {
  @JsonValue('theory')
  theory,
  @JsonValue('exercise')
  exercise,
  @JsonValue('roleplay')
  roleplay,
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
    subQuestions: subQuestions.map((model) => model.toEntity()).toList(),
    documents: documents.map((model) => model.toEntity()).toList(),
    sections: sections.map((model) => model.toEntity()).toList(),
    tag: tag,
    index: index,
    isSub: isSub,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
