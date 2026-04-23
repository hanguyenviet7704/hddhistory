part of '../../progress.dart';

@freezed
abstract class UserProgressEntity with _$UserProgressEntity {
  const factory UserProgressEntity({
    @Default('') String id,
    @Default('') String userId,
    @Default('') String courseId,
    @Default([]) List<LessonResultEntity> lessonsResult,
    @Default([]) List<CompletedLevelEntity> completedLevels,
  }) = _UserProgressEntity;

  factory UserProgressEntity.fromJson(Map<String, dynamic> json) => _$UserProgressEntityFromJson(json);
}
