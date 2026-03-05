part of '../../learning_streak.dart';

enum LearningStreakDataOrigin { unknown, remote, cache, safeDefault }

@freezed
abstract class LearningStreakFetchEntity with _$LearningStreakFetchEntity {
  const factory LearningStreakFetchEntity({
    @Default(UserLearningStreakEntity()) UserLearningStreakEntity streak,
    @Default(LearningStreakDataOrigin.unknown) LearningStreakDataOrigin origin,
  }) = _LearningStreakFetchEntity;

  factory LearningStreakFetchEntity.fromJson(Map<String, dynamic> json) => _$LearningStreakFetchEntityFromJson(json);
}
