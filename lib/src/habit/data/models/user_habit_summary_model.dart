part of '../../habit.dart';

@freezed
abstract class UserHabitSummaryModel with _$UserHabitSummaryModel {
  const factory UserHabitSummaryModel({
    @Default(0) int checkInRate,
    @Default(0) int activeCount,
    @Default(0) int bestStreak,
    @Default(0) int totalCheckIns,
  }) = _UserHabitSummaryModel;

  factory UserHabitSummaryModel.fromJson(Map<String, dynamic> json) => _$UserHabitSummaryModelFromJson(json);
}

extension UserHabitSummaryModelX on UserHabitSummaryModel {
  UserHabitSummaryEntity toEntity() => UserHabitSummaryEntity(
    checkInRate: checkInRate,
    activeCount: activeCount,
    bestStreak: bestStreak,
    totalCheckIns: totalCheckIns,
  );
}
