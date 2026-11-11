part of '../../../course/course.dart';

@freezed
abstract class LearningItemEntity with _$LearningItemEntity {
  const factory LearningItemEntity({
    @Default('') String id,
    @Default(UserEntity()) UserEntity createdBy,
    @Default(UserEntity()) UserEntity updatedBy,
    @Default('') String keypointId,
    @Default(BaseMultiLanguage(en: '')) BaseMultiLanguage title,
    @Default(BaseMultiLanguage(en: '')) BaseMultiLanguage description,
    @Default(BaseMultiLanguage(en: '')) BaseMultiLanguage estimateCompleTime,
    @Default('') String image,
    @Default(LearningItemType.theory) LearningItemType type,
    @Default([]) List<QuestionEntity> mainQuestions,
    @Default([]) List<QuestionEntity> subQuestions,
    @Default([]) List<VideoQuestionEntity> videoQuestions,
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
  List<QuestionEntity> get questions {
    // if (type == LearningItemType.exercise) return mainQuestions;
    //  if (type == LearningItemType.roleplay) {
    //   if (roleplay.contents.isEmpty) return [];
    //   return roleplay.contents.map((content) => content.exercise).toList();
    // }
    // return [];
    return mainQuestions;
  }

  bool get isPlayingMainQuestions => !isPlayingSubQuestions && !isPlayingRoleplayQuestions;
}
