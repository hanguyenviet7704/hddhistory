part of '../../../course/course.dart';

@freezed
abstract class LearningItemEntity with _$LearningItemEntity {
  const factory LearningItemEntity({
    @Default('') String id,
    @Default(AppUser()) AppUser createdBy,
    @Default(AppUser()) AppUser updatedBy,
    @Default('') String keypointId,
    @Default(BaseMultiLanguage(en: '')) BaseMultiLanguage title,
    @Default('') String image,
    @Default(LearningItemType.theory) LearningItemType type,
    @Default([]) List<QuestionEntity> questions,
    @Default([]) List<QuestionEntity> subQuestions,
    @Default([]) List<DocumentEntity> documents,
    @Default([]) List<SectionEntity> sections,
    @Default([]) List<String> tag,
    @Default(0) int index,
    @Default(false) bool isSub,
    @Default(false) bool isPlayingSubQuestions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _LearningItemEntity;

  factory LearningItemEntity.fromJson(Map<String, dynamic> json) => _$LearningItemEntityFromJson(json);
}
