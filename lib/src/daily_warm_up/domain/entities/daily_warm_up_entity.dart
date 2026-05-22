part of '../../daily_warm_up.dart';

@freezed
abstract class DailyWarmUpEntity with _$DailyWarmUpEntity {
  const factory DailyWarmUpEntity({
    @Default('') String courseId,
    @Default('') String suggestedCourseId,
    @Default('') String lessonId,
    @Default('') String lessonIdkeypointId,
    @Default(false) bool isKeypointCompleted,
    @Default([]) List<QuestionEntity> questions,
  }) = _DailyWarmUpEntity;

  factory DailyWarmUpEntity.fromJson(Map<String, dynamic> json) => _$DailyWarmUpEntityFromJson(json);
}

