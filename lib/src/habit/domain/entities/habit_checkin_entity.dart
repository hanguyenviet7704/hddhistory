part of '../../habit.dart';

/// One day's check-in record for a habit — powers the Habit-detail monthly
/// heatmap and the diary list (§9.8). `note` is the optional diary entry
/// written at check-in time (§9.7).
@freezed
abstract class HabitCheckinEntity with _$HabitCheckinEntity {
  const factory HabitCheckinEntity({
    required DateTime date,
    @Default(true) bool done,
    String? note,
  }) = _HabitCheckinEntity;
}
