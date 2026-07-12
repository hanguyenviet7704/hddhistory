part of '../../habit.dart';

@freezed
abstract class UserHabitSummaryEntity with _$UserHabitSummaryEntity {
  const factory UserHabitSummaryEntity({
    @Default(0) int checkInRate,
    @Default(0) int activeCount,
    @Default(0) int bestStreak,
    @Default(0) int totalCheckIns,
  }) = _UserHabitSummaryEntity;

  factory UserHabitSummaryEntity.fromJson(Map<String, dynamic> json) => _$UserHabitSummaryEntityFromJson(json);
}
