part of '../../lesson.dart';

@freezed
abstract class LessonEntity with _$LessonEntity {
  const factory LessonEntity({
    @Default('') String id,
    @Default('') String courseId,
    @Default(LessonType.lesson) LessonType type,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default(LessonPublishStatus.draft) LessonPublishStatus status,
    @Default([]) List<String> keypoints,
    @Default(BaseMultiLanguage()) BaseMultiLanguage estimateCompleTime,
    @Default('') String icon,
    @Default(0) int index,
  }) = _LessonEntity;

  factory LessonEntity.fromJson(Map<String, dynamic> json) => _$LessonEntityFromJson(json);
}
