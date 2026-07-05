part of '../../warm_up.dart';

@freezed
abstract class WarmUpPreviousLessonEntity with _$WarmUpPreviousLessonEntity {
  const factory WarmUpPreviousLessonEntity({
    @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default([]) List<QuestionEntity> questions,
  }) = _WarmUpPreviousLessonEntity;

  factory WarmUpPreviousLessonEntity.fromJson(Map<String, dynamic> json) => _$WarmUpPreviousLessonEntityFromJson(json);
}
