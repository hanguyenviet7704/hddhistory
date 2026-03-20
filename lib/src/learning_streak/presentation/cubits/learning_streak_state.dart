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
  }) = _LearningStreakState;

  factory LearningStreakState.initial() => LearningStreakState();

  factory LearningStreakState.fromJson(Map<String, dynamic> json) => _$LearningStreakStateFromJson(json);
}

extension LearningStreakStateExtension on LearningStreakState {
  DateTime? get lastStreakCountedUtcDay {
    if (lastStreakCountedDate == null) return null;
    final value = lastStreakCountedDate!.toUtc();
    return DateTime.utc(value.year, value.month, value.day);
  }

  bool isSameStreakCountedUtcDay(DateTime utcDate) {
    final previousDay = lastStreakCountedUtcDay;
    if (previousDay == null) return false;
    final normalized = DateTime.utc(utcDate.year, utcDate.month, utcDate.day);
    return previousDay == normalized;
  }
}
