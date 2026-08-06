part of '../../habit.dart';

/// Response of `POST /habit-practices/attempts`.
///
/// The endpoint writes twice — the attempt row and the day's check-in — and
/// returns the refreshed user habit so the app can update its card (streak,
/// today's tick) from the same response, without a follow-up fetch that could
/// race the write.
@freezed
abstract class HabitPracticeAttemptResultModel with _$HabitPracticeAttemptResultModel {
  const factory HabitPracticeAttemptResultModel({
    UserHabitModel? userHabit,
  }) = _HabitPracticeAttemptResultModel;

  factory HabitPracticeAttemptResultModel.fromJson(Map<String, dynamic> json) =>
      _$HabitPracticeAttemptResultModelFromJson(json);
}
