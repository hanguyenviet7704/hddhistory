part of '../../habit.dart';

/// How a day's check-in was filed.
///
/// Names match the API's `HabitCheckinMethod` wire values exactly, so
/// [apiValue] is just `name`. `tap` is the quick toggle on the 7-day strip;
/// the rest come from the "Practice now" flow, where the picker asks "How do
/// you want to check in?" — a finished practice *is* the day's check-in.
///
/// `unknown` covers rows written before practice shipped (no `method` at all)
/// and any value a newer API adds. Those read as [tap] in the UI, because the
/// quick toggle is where they came from.
enum HabitCheckinMethodEntity {
  tap,
  journal,
  exercise,
  video,
  roleplay,
  unknown;

  /// Value to send to the API, or null when there is nothing meaningful to send.
  String? get apiValue => this == HabitCheckinMethodEntity.unknown ? null : name;

  static HabitCheckinMethodEntity fromApi(String? value) =>
      HabitCheckinMethodEntity.values.firstWhere(
        (method) => method.name == value,
        orElse: () => HabitCheckinMethodEntity.unknown,
      );
}

/// One day's check-in record for a habit — powers the Habit-detail monthly
/// heatmap and the diary list (§9.8). `note` is the optional diary entry
/// written at check-in time (§9.7), and also carries the free text of a
/// journal practice.
@freezed
abstract class HabitCheckinEntity with _$HabitCheckinEntity {
  const factory HabitCheckinEntity({
    required DateTime date,
    @Default(true) bool done,
    String? note,
    @Default(HabitCheckinMethodEntity.unknown) HabitCheckinMethodEntity method,
    /// Journal mood on a 3-level scale, 1-based. Never 0 — see the API's
    /// habit-checkin.schema.ts for why.
    int? mood,

    /// Correct-answer count of a quiz practice.
    int? score,
  }) = _HabitCheckinEntity;
}
