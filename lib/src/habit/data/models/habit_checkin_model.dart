part of '../../habit.dart';

@freezed
abstract class HabitCheckinModel with _$HabitCheckinModel {
  const factory HabitCheckinModel({
    String? date,
    @Default(true) bool done,
    String? note,
    // Kept as the raw wire string rather than the enum: a value the app does
    // not know yet must not fail deserialization of the whole check-in log.
    // [HabitCheckinMethodEntity.fromApi] maps it, falling back to `unknown`.
    String? method,
    int? mood,
    int? score,
  }) = _HabitCheckinModel;

  factory HabitCheckinModel.fromJson(Map<String, dynamic> json) => _$HabitCheckinModelFromJson(json);
}

extension HabitCheckinModelX on HabitCheckinModel {
  HabitCheckinEntity toEntity() => HabitCheckinEntity(
    // Date-only from the API ("2026-07-05"); keep as the calendar date (no TZ
    // shift) so heatmap cells land on the right day.
    date: DateTime.tryParse(date ?? '') ?? DateTime.now(),
    done: done,
    note: note,
    method: HabitCheckinMethodEntity.fromApi(method),
    mood: mood,
    score: score,
  );
}
