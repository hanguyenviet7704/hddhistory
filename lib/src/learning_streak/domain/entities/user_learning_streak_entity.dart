part of '../../learning_streak.dart';

@freezed
abstract class UserLearningStreakEntity with _$UserLearningStreakEntity {
  const factory UserLearningStreakEntity({
    @Default('') String id,
    @Default('') String name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserLearningStreakEntity;

  factory UserLearningStreakEntity.fromJson(Map<String, dynamic> json) => _$UserLearningStreakEntityFromJson(json);
}

