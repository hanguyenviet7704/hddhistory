part of '../../learning_streak.dart';

enum LearningStreakStatus { initial, loading, success, failure }

enum LearningStreakTriggerSource { unknown, completionCta, homeChip }

@freezed
abstract class LearningStreakState with _$LearningStreakState {
  const factory LearningStreakState({
    @Default(LearningStreakStatus.initial) LearningStreakStatus status,
    @Default(UserLearningStreakEntity()) UserLearningStreakEntity selectedItem,
    String? errorMessage,
    @Default('') String requestId,
    @Default(LearningStreakTriggerSource.unknown) LearningStreakTriggerSource triggerSource,
    @Default('') String requestedUserId,
    @Default(LearningStreakDataOrigin.unknown) LearningStreakDataOrigin dataOrigin,
    @Default(null) DateTime? lastStreakCountedDate,
    // Two separate once-a-day latches, because they now guard different things:
    // this one stops a second check-in POST, `lastStreakCountedDate` stops a
    // second toast. Collapsing them would make the app POST every ten seconds
    // all day whenever `popupEnabled` is off, since no toast would ever be shown
    // to spend the other latch.
    @Default(null) DateTime? lastCheckInDate,
  }) = _LearningStreakState;

  factory LearningStreakState.initial() => LearningStreakState();

  factory LearningStreakState.fromJson(Map<String, dynamic> json) => _$LearningStreakStateFromJson(json);
}

extension LearningStreakStateExtension on LearningStreakState {
  /// Local day the toast was last shown on — see [StreakDay] for why these are
  /// local days rather than UTC ones.
  DateTime? get lastStreakCountedDay {
    if (lastStreakCountedDate == null) return null;
    return StreakDay.resolve(lastStreakCountedDate!);
  }

  bool isSameStreakCountedDay(DateTime value) => StreakDay.isSame(lastStreakCountedDate, value);

  /// Local day the app last told the server the user showed up.
  DateTime? get lastCheckInDay {
    if (lastCheckInDate == null) return null;
    return StreakDay.resolve(lastCheckInDate!);
  }

  bool isSameCheckInDay(DateTime value) => StreakDay.isSame(lastCheckInDate, value);
}
