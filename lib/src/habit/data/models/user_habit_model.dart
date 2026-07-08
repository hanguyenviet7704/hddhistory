part of '../../habit.dart';

@freezed
abstract class UserHabitModel with _$UserHabitModel {
  const factory UserHabitModel({
    @JsonKey(name: '_id') @Default('') String id,
    @Default('') String habitId,
    @Default(UserHabitStateEntity.unknown) UserHabitStateEntity state,
    String? reminderTime,
    @Default(3) int packLength,
    DateTime? startedAt,
    @Default(0) int currentStreak,
    @Default(0) int bestStreak,
    @Default(0) int totalCheckIns,
    DateTime? lastCheckInDate,
    HabitModel? habit,
    @Default(false) bool todayDone,
    DateTime? weekStartDate,
    @Default([]) List<bool> weekGrid,
    String? sourceKeypointId,
    String? sourceCourseId,
  }) = _UserHabitModel;

  factory UserHabitModel.fromJson(Map<String, dynamic> json) => _$UserHabitModelFromJson(json);
}

extension UserHabitModelX on UserHabitModel {
  UserHabitEntity toEntity() => UserHabitEntity(
    id: id,
    habitId: habitId,
    state: state,
    reminderTime: reminderTime,
    packLength: packLength,
    startedAt: startedAt,
    currentStreak: currentStreak,
    bestStreak: bestStreak,
    totalCheckIns: totalCheckIns,
    lastCheckInDate: lastCheckInDate,
    habit: habit?.toEntity(),
    todayDone: todayDone,
    weekStartDate: weekStartDate,
    weekGrid: weekGrid,
    sourceKeypointId: sourceKeypointId,
    sourceCourseId: sourceCourseId,
  );
}
