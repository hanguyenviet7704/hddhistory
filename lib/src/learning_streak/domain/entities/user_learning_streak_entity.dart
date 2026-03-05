part of '../../learning_streak.dart';

const List<bool> kLearningStreakEmptyWeekStudy = <bool>[
  false,
  false,
  false,
  false,
  false,
  false,
  false,
];

@freezed
abstract class UserLearningStreakEntity with _$UserLearningStreakEntity {
  const factory UserLearningStreakEntity({
    @Default('') String userId,
    DateTime? weekStartDate,
    @Default(kLearningStreakEmptyWeekStudy) List<bool> weekStudy,
    @Default(0) int studyTime,
    @Default(0) int currentStreak,
    @Default(0) int bestStreak,
  }) = _UserLearningStreakEntity;

  factory UserLearningStreakEntity.fromJson(Map<String, dynamic> json) => _$UserLearningStreakEntityFromJson(json);
}

extension UserLearningStreakEntityExtension on UserLearningStreakEntity {
  List<bool> get normalizedWeekStudy {
    if (weekStudy.length != 7) return List<bool>.from(kLearningStreakEmptyWeekStudy);
    return List<bool>.from(weekStudy);
  }
}
