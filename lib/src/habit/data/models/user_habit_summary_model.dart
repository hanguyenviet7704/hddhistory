part of '../../habit.dart';

@freezed
abstract class UserHabitSummaryModel with _$UserHabitSummaryModel {
  const factory UserHabitSummaryModel({
    @Default(0) int checkInRate,
    @Default(0) int activeCount,
    @Default(0) int bestStreak,
    @Default(0) int totalCheckIns,
    @Default(0) int totalLessons,
    HabitBestHabitModel? bestHabit,
    @Default(false) bool isRecapDay,
    DateTime? weekStartDate,
  }) = _UserHabitSummaryModel;

  factory UserHabitSummaryModel.fromJson(Map<String, dynamic> json) => _$UserHabitSummaryModelFromJson(json);
}

/// The user's strongest habit for the Weekly recap "Best habit" card (Figma):
/// its title + loop length (best streak in days).
@freezed
abstract class HabitBestHabitModel with _$HabitBestHabitModel {
  const factory HabitBestHabitModel({
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(0) int loop,
  }) = _HabitBestHabitModel;

  factory HabitBestHabitModel.fromJson(Map<String, dynamic> json) => _$HabitBestHabitModelFromJson(json);
}

extension UserHabitSummaryModelX on UserHabitSummaryModel {
  UserHabitSummaryEntity toEntity() => UserHabitSummaryEntity(
    checkInRate: checkInRate,
    activeCount: activeCount,
    bestStreak: bestStreak,
    totalCheckIns: totalCheckIns,
    totalLessons: totalLessons,
    bestHabit: bestHabit == null ? null : HabitBestHabitEntity(title: bestHabit!.title, loop: bestHabit!.loop),
    isRecapDay: isRecapDay,
    weekStartDate: weekStartDate,
  );
}
