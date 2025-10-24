part of '../../exercise.dart';

@freezed
abstract class LearningItemEntity with _$LearningItemEntity {
  const factory LearningItemEntity({
    @Default('') String id,
    @Default(AppUser()) AppUser createdBy,
    @Default(AppUser()) AppUser updatedBy,
    @Default('') String keypointId,
    @Default(BaseMultiLanguage(en: '')) BaseMultiLanguage title,
    @Default('') String image,
    @Default('') String type,
    @Default([]) List<QuestionEntity> questions,
    @Default(0) int index,
    @Default(false) bool isSub,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _LearningItemEntity;

  factory LearningItemEntity.fromJson(Map<String, dynamic> json) => _$LearningItemEntityFromJson(json);
}
