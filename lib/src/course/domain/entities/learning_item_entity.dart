part of '../../../course/course.dart';

@freezed
abstract class LearningItemEntity with _$LearningItemEntity {
  const factory LearningItemEntity({
    @Default('') String id,
    @Default(AppUser()) AppUser createdBy,
    @Default(AppUser()) AppUser updatedBy,
    @Default('') String keypointId,
    @Default(BaseMultiLanguage(en: '')) BaseMultiLanguage title,
    @Default(BaseMultiLanguage(en: '')) BaseMultiLanguage description,
    @Default(BaseMultiLanguage(en: '')) BaseMultiLanguage estimateCompleTime,
    @Default('') String image,
    @Default(LearningItemType.theory) LearningItemType type,
    @Default([]) List<QuestionEntity> mainQuestions,
    @Default([]) List<QuestionEntity> subQuestions,
    @Default([]) List<DocumentEntity> documents,
    @Default(RoleplayEntity()) RoleplayEntity roleplay,
    @Default([]) List<String> tag,
    @Default(0) int index,
    @Default(false) bool isSub,
    DateTime? createdAt,
    DateTime? updatedAt,

    //* Custom Fields
    @Default(0) int sectionQuestionIndex,
    @Default(false) bool isPlayingSubQuestions,
    @Default(false) bool isPlayingRoleplayQuestions,
  }) = _LearningItemEntity;

  factory LearningItemEntity.fromJson(Map<String, dynamic> json) => _$LearningItemEntityFromJson(json);
}

extension LearningItemEntityExtension on LearningItemEntity {
  bool get isPlayingMainQuestions => !isPlayingSubQuestions && !isPlayingRoleplayQuestions;

  List<QuestionEntity> get questions {
    if (type == LearningItemType.exercise) return mainQuestions;
    return [];
  }
}
