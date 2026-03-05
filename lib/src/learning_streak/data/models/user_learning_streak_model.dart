part of '../../learning_streak.dart';

@freezed
abstract class UserLearningStreakModel with _$UserLearningStreakModel {
  const factory UserLearningStreakModel({
    @Default('') String userId,
    DateTime? weekStartDate,
    @Default(kLearningStreakEmptyWeekStudy) List<bool> weekStudy,
    @Default(0) int studyTime,
    @Default(0) int currentStreak,
    @Default(0) int bestStreak,
  }) = _UserLearningStreakModel;

  factory UserLearningStreakModel.fromJson(Map<String, dynamic> json) => _$UserLearningStreakModelFromJson(json);
}

extension UserLearningStreakModelExtension on UserLearningStreakModel {
  UserLearningStreakModel sanitized() => copyWith(
    weekStudy: _sanitizeWeekStudy(weekStudy),
    studyTime: _sanitizeInt(studyTime),
    currentStreak: _sanitizeInt(currentStreak),
    bestStreak: _sanitizeInt(bestStreak),
  );

  UserLearningStreakEntity toEntity() {
    final normalized = sanitized();
    return UserLearningStreakEntity(
      userId: normalized.userId,
      weekStartDate: normalized.weekStartDate,
      weekStudy: normalized.weekStudy,
      studyTime: normalized.studyTime,
      currentStreak: normalized.currentStreak,
      bestStreak: normalized.bestStreak,
    );
  }

  int _sanitizeInt(int value) {
    if (value < 0) return 0;
    return value;
  }

  List<bool> _sanitizeWeekStudy(List<bool> values) {
    if (values.length != 7) return List<bool>.from(kLearningStreakEmptyWeekStudy);
    return List<bool>.from(values);
  }
}
