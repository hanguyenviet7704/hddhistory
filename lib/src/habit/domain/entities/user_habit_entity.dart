part of '../../habit.dart';

enum UserHabitStateEntity {
  @JsonValue('active')
  active,
  @JsonValue('draft')
  draft,
  @JsonValue('archived')
  archived,
  @JsonValue('unknown')
  unknown,
}

@freezed
abstract class UserHabitEntity with _$UserHabitEntity {
  const factory UserHabitEntity({
    @Default('') String id,
    @Default('') String habitId,
    @Default(UserHabitStateEntity.unknown) UserHabitStateEntity state,
    String? reminderTime,
    @Default(3) int packLength,
    DateTime? startedAt,
    @Default(0) int currentStreak,
    @Default(0) int bestStreak,
    @Default(0) int totalCheckIns,
    DateTime? lastCheckInDate,
    HabitEntity? habit,
    @Default(false) bool todayDone,
    DateTime? weekStartDate,
    @Default([]) List<bool> weekGrid,
    // Where the habit was adopted from (§9.5 grouping by course, §9.2 FR2.8
    // "each lesson suggests once" gating).
    String? sourceLessonId,
    String? sourceCourseId,
  }) = _UserHabitEntity;

  factory UserHabitEntity.fromJson(Map<String, dynamic> json) => _$UserHabitEntityFromJson(json);
}

extension UserHabitEntityX on UserHabitEntity {
  bool get isActive => state == UserHabitStateEntity.active;
  bool get isDraft => state == UserHabitStateEntity.draft;
  String get displayTitle => habit?.title.text ?? '';
  String get displayIcon => habit?.icon ?? '';
}
