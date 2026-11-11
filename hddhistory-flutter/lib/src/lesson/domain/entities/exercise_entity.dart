part of '../../lesson.dart';

@freezed
abstract class ExerciseEntity with _$ExerciseEntity {
  const factory ExerciseEntity({
    @Default('') String id,
    @Default(UserEntity()) UserEntity createdBy,
    @Default(UserEntity()) UserEntity updatedBy,
    @Default('') String keypointId,
    @Default(BaseMultiLanguage(en: '')) BaseMultiLanguage title,
    @Default('') String image,
    @Default('') String type,
    @Default([]) List<QuestionEntity> questions,
    @Default(0) int index,
    @Default(false) bool isSub,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ExerciseEntity;

  factory ExerciseEntity.fromJson(Map<String, dynamic> json) => _$ExerciseEntityFromJson(json);
}
