part of '../../learning_streak.dart';

@freezed
abstract class UserLearningStreakModel with _$UserLearningStreakModel {
  const factory UserLearningStreakModel({
    @Default('') String userId,
    DateTime? weekStartDate,
    @Default(<bool>[]) List<bool> weekStudy,
    @Default(0) int studyTime,
    @Default(0) int currentStreak,
    @Default(0) int bestStreak,
  }) = _UserLearningStreakModel;


  factory UserLearningStreakModel.fromJson(Map<String, dynamic> json) => _$UserLearningStreakModelFromJson(json);
}

extension UserLearningStreakModelExtension on UserLearningStreakModel {
  UserLearningStreakEntity toEntity() => UserLearningStreakEntity(
        userId: userId,
        weekStartDate: weekStartDate,
        weekStudy: weekStudy,
        studyTime: studyTime,
        currentStreak: currentStreak,
        bestStreak: bestStreak,
      );
}

