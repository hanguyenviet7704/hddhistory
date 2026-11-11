part of '../../week_recap.dart';

@freezed
abstract class WeekRecapDayModel with _$WeekRecapDayModel {
  const factory WeekRecapDayModel({
    @Default('') String date,
    @Default(false) bool active,
    int? mood,
  }) = _WeekRecapDayModel;

  factory WeekRecapDayModel.fromJson(Map<String, dynamic> json) => _$WeekRecapDayModelFromJson(json);
}

@freezed
abstract class WeekRecapLessonModel with _$WeekRecapLessonModel {
  const factory WeekRecapLessonModel({
    @Default('') String courseId,
    @Default('') String courseTitle,
    @Default('') String image,
    @Default('') String lessonId,
    @Default('') String lessonTitle,
  }) = _WeekRecapLessonModel;

  factory WeekRecapLessonModel.fromJson(Map<String, dynamic> json) => _$WeekRecapLessonModelFromJson(json);
}

@freezed
abstract class WeekRecapHabitModel with _$WeekRecapHabitModel {
  const factory WeekRecapHabitModel({
    @Default('') String habitId,
    @Default('') String title,
    @Default(0) int doneCount,
  }) = _WeekRecapHabitModel;

  factory WeekRecapHabitModel.fromJson(Map<String, dynamic> json) => _$WeekRecapHabitModelFromJson(json);
}

@freezed
abstract class WeekRecapCourseModel with _$WeekRecapCourseModel {
  const factory WeekRecapCourseModel({
    @Default('') String courseId,
    @Default('') String title,
    @Default('') String image,
  }) = _WeekRecapCourseModel;

  factory WeekRecapCourseModel.fromJson(Map<String, dynamic> json) => _$WeekRecapCourseModelFromJson(json);
}

@freezed
abstract class WeekRecapStatsModel with _$WeekRecapStatsModel {
  const factory WeekRecapStatsModel({
    @Default(0) int activeDays,
    @Default(0) int streakDays,
    @Default(0) int habitsKept,
    @Default(0) int keypoints,
    @Default(0) int minutes,
  }) = _WeekRecapStatsModel;

  factory WeekRecapStatsModel.fromJson(Map<String, dynamic> json) => _$WeekRecapStatsModelFromJson(json);
}

@freezed
abstract class WeekRecapModel with _$WeekRecapModel {
  const factory WeekRecapModel({
    @Default('') String id,
    @Default(0) int weekNumber,
    @Default('') String weekStart,
    @Default('') String weekEnd,
    @Default(WeekRecapStatsModel()) WeekRecapStatsModel stats,
    @Default(<WeekRecapDayModel>[]) List<WeekRecapDayModel> days,
    @Default(<WeekRecapLessonModel>[]) List<WeekRecapLessonModel> lessons,
    @Default(<WeekRecapHabitModel>[]) List<WeekRecapHabitModel> habits,
    WeekRecapCourseModel? favouriteCourse,
    String? viewedAt,
    String? dismissedAt,
  }) = _WeekRecapModel;

  factory WeekRecapModel.fromJson(Map<String, dynamic> json) => _$WeekRecapModelFromJson(json);
}

@freezed
abstract class WeekRecapSummaryModel with _$WeekRecapSummaryModel {
  const factory WeekRecapSummaryModel({
    @Default('') String id,
    @Default(0) int weekNumber,
    @Default('') String weekStart,
    @Default('') String weekEnd,
  }) = _WeekRecapSummaryModel;

  factory WeekRecapSummaryModel.fromJson(Map<String, dynamic> json) => _$WeekRecapSummaryModelFromJson(json);
}

@freezed
abstract class CurrentWeekRecapModel with _$CurrentWeekRecapModel {
  const factory CurrentWeekRecapModel({
    WeekRecapModel? recap,
    @Default(0) int archiveCount,
  }) = _CurrentWeekRecapModel;

  factory CurrentWeekRecapModel.fromJson(Map<String, dynamic> json) => _$CurrentWeekRecapModelFromJson(json);
}

extension WeekRecapDayModelX on WeekRecapDayModel {
  WeekRecapDayEntity toEntity() => WeekRecapDayEntity(
    // A malformed day still has to occupy its cell: the calendar is a fixed
    // seven-column grid, and dropping one would slide the rest of the week
    // onto the wrong columns.
    date: parseWeekRecapDay(date) ?? DateTime.now(),
    active: active,
    mood: WeekRecapMood.fromValue(mood),
  );
}

extension WeekRecapModelX on WeekRecapModel {
  WeekRecapEntity toEntity() {
    final start = parseWeekRecapInstant(weekStart) ?? DateTime.now();
    final favourite = favouriteCourse;

    return WeekRecapEntity(
      id: id,
      weekNumber: weekNumber,
      weekStart: start,
      weekEnd: parseWeekRecapInstant(weekEnd) ?? start.add(const Duration(days: 7)),
      stats: WeekRecapStatsEntity(
        activeDays: stats.activeDays,
        streakDays: stats.streakDays,
        habitsKept: stats.habitsKept,
        keypoints: stats.keypoints,
        minutes: stats.minutes,
      ),
      days: days.map((day) => day.toEntity()).toList(),
      lessons: lessons
          .map(
            (lesson) => WeekRecapLessonEntity(
              courseId: lesson.courseId,
              courseTitle: lesson.courseTitle,
              image: lesson.image,
              lessonId: lesson.lessonId,
              lessonTitle: lesson.lessonTitle,
            ),
          )
          .toList(),
      habits: habits
          .map(
            (habit) => WeekRecapHabitEntity(
              habitId: habit.habitId,
              title: habit.title,
              doneCount: habit.doneCount,
            ),
          )
          .toList(),
      favouriteCourse: favourite == null
          ? null
          : WeekRecapCourseEntity(
              courseId: favourite.courseId,
              title: favourite.title,
              image: favourite.image,
            ),
      viewedAt: parseWeekRecapInstant(viewedAt),
      dismissedAt: parseWeekRecapInstant(dismissedAt),
    );
  }
}

extension WeekRecapSummaryModelX on WeekRecapSummaryModel {
  WeekRecapSummaryEntity toEntity() {
    final start = parseWeekRecapInstant(weekStart) ?? DateTime.now();

    return WeekRecapSummaryEntity(
      id: id,
      weekNumber: weekNumber,
      weekStart: start,
      weekEnd: parseWeekRecapInstant(weekEnd) ?? start.add(const Duration(days: 7)),
    );
  }
}

extension CurrentWeekRecapModelX on CurrentWeekRecapModel {
  CurrentWeekRecapEntity toEntity() => CurrentWeekRecapEntity(
    recap: recap?.toEntity(),
    archiveCount: archiveCount,
  );
}

/// A `YYYY-MM-DD` calendar day, read as a LOCAL date.
///
/// `DateTime.parse` reads a bare date as UTC midnight, and formatting that back
/// for display would show the day before for anyone west of Greenwich.
DateTime? parseWeekRecapDay(String? value) {
  if (value == null || value.isEmpty) return null;
  final parts = value.split('-');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;

  return DateTime(year, month, day);
}

/// An ISO instant, brought into local time.
///
/// `weekStart` is the learner's own Monday midnight expressed in UTC, so it has
/// to come back through `toLocal()` before anything reads its calendar parts —
/// otherwise the poster's month header can land a day out.
DateTime? parseWeekRecapInstant(String? value) {
  if (value == null || value.isEmpty) return null;

  return DateTime.tryParse(value)?.toLocal();
}
