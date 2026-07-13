part of '../../habit.dart';

@freezed
abstract class UserHabitSummaryEntity with _$UserHabitSummaryEntity {
  const factory UserHabitSummaryEntity({
    @Default(0) int checkInRate,
    @Default(0) int activeCount,
    @Default(0) int bestStreak,
    @Default(0) int totalCheckIns,
    @Default(0) int totalLessons,
    HabitBestHabitEntity? bestHabit,
    // Server-driven Weekly-recap trigger (device clock not trusted): whether
    // the server considers today the recap day (Sunday), and the start of the
    // week being recapped (used to show the recap once per server-week).
    @Default(false) bool isRecapDay,
    DateTime? weekStartDate,
  }) = _UserHabitSummaryEntity;

  factory UserHabitSummaryEntity.fromJson(Map<String, dynamic> json) => _$UserHabitSummaryEntityFromJson(json);
}

@freezed
abstract class HabitBestHabitEntity with _$HabitBestHabitEntity {
  const factory HabitBestHabitEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(0) int loop,
  }) = _HabitBestHabitEntity;

  factory HabitBestHabitEntity.fromJson(Map<String, dynamic> json) => _$HabitBestHabitEntityFromJson(json);
}
