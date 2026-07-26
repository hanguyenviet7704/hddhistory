part of '../../habit.dart';

/// Combined Habit-tab bootstrap payload: the tracker's habits, weekly
/// summary, and free-tier slot cap fetched together via
/// `GetHabitScreenUseCase` — replaces three separate initial-load calls.
@freezed
abstract class HabitScreenEntity with _$HabitScreenEntity {
  const factory HabitScreenEntity({
    @Default(kFreeActiveHabitSlots) int freeActiveSlots,
    @Default([]) List<UserHabitEntity> habits,
    @Default(UserHabitSummaryEntity()) UserHabitSummaryEntity summary,
  }) = _HabitScreenEntity;

  factory HabitScreenEntity.fromJson(Map<String, dynamic> json) => _$HabitScreenEntityFromJson(json);
}
