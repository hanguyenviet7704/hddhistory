part of '../../learning_streak.dart';

@freezed
abstract class UserLearningStreakEntity with _$UserLearningStreakEntity {
  const factory UserLearningStreakEntity({
    @Default('') String userId,
    DateTime? weekStartDate,
    @Default(<bool>[]) List<bool> weekStudy,
    @Default(0) int studyTime,
    @Default(0) int currentStreak,
    @Default(0) int bestStreak,
  }) = _UserLearningStreakEntity;

  factory UserLearningStreakEntity.fromJson(Map<String, dynamic> json) => _$UserLearningStreakEntityFromJson(json);
}

