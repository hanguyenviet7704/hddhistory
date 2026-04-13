part of '../../../course/course.dart';

@freezed
abstract class LearningItemModel with _$LearningItemModel {
  const factory LearningItemModel({
    @Default('') @JsonKey(name: '_id') String id,
    @Default(UserModel()) UserModel createdBy,
    @Default(UserModel()) UserModel updatedBy,
    @Default('') String keypointId,
    @Default(BaseMultiLanguage(en: '')) BaseMultiLanguage title,
    @Default(BaseMultiLanguage(en: '')) BaseMultiLanguage description,
    @Default(BaseMultiLanguage(en: '')) BaseMultiLanguage estimateCompleTime,
    @Default('') String image,
    @JsonKey(unknownEnumValue: LearningItemType.unknown) @Default(LearningItemType.theory) LearningItemType type,
    @Default([]) List<QuestionModel> questions,
    @Default([]) List<QuestionModel> subQuestions,
    @Default([]) List<VideoQuestionModel> videoQuestions,
    @Default([]) List<DocumentModel> documents,
    @Default(RoleplayModel()) RoleplayModel roleplay,
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
  @JsonValue('video')
  video,
  @JsonValue('unknown')
  unknown,
}

extension LearningItemModelExtension on LearningItemModel {
  LearningItemEntity toEntity() => LearningItemEntity(
    id: id,
    createdBy: createdBy.toEntity(),
    updatedBy: updatedBy.toEntity(),
    keypointId: keypointId,
    title: title,
    description: description,
    estimateCompleTime: estimateCompleTime,
    image: image,
    type: type,
    mainQuestions: questions.map((model) => model.toEntity()).toList(),
    subQuestions: subQuestions.map((model) => model.toEntity()).toList(),
    videoQuestions: videoQuestions.map((model) => model.toEntity()).toList(),
    documents: documents.map((model) => model.toEntity()).toList(),
    roleplay: roleplay.toEntity(),
    tag: tag,
    index: index,
    isSub: isSub,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
