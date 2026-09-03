part of '../../week_recap.dart';

/// The three journal moods, as the poster draws them.
///
/// 1-based to match the server, which is 1-based because `mood: 0` is falsy in
/// both Dart and JS — every `if (mood)` in the app and admin would silently
/// drop the lowest level.
enum WeekRecapMood {
  low(1),
  ok(2),
  good(3);

  const WeekRecapMood(this.value);

  final int value;

  static WeekRecapMood? fromValue(int? value) {
    if (value == null) return null;

    return WeekRecapMood.values.firstWhereOrNull((mood) => mood.value == value);
  }
}

/// One of the seven cells on the poster's calendar row.
@freezed
abstract class WeekRecapDayEntity with _$WeekRecapDayEntity {
  const factory WeekRecapDayEntity({
    required DateTime date,
    @Default(false) bool active,

    /// Null when the learner filed no journal that day. The poster then leaves
    /// the cell without a chip so its date number shows through — a day off
    /// must not read as a bad day.
    WeekRecapMood? mood,
  }) = _WeekRecapDayEntity;
}

/// A row of the poster's "BÀI HỌC TUẦN QUA" notepad.
@freezed
abstract class WeekRecapLessonEntity with _$WeekRecapLessonEntity {
  const factory WeekRecapLessonEntity({
    @Default('') String courseId,
    @Default('') String courseTitle,
    @Default('') String image,
    @Default('') String lessonId,
    @Default('') String lessonTitle,
  }) = _WeekRecapLessonEntity;
}

/// A line of the poster's "THÓI QUEN ĐÃ GIỮ" list.
@freezed
abstract class WeekRecapHabitEntity with _$WeekRecapHabitEntity {
  const factory WeekRecapHabitEntity({
    @Default('') String habitId,
    @Default('') String title,
    @Default(0) int doneCount,
  }) = _WeekRecapHabitEntity;
}

@freezed
abstract class WeekRecapCourseEntity with _$WeekRecapCourseEntity {
  const factory WeekRecapCourseEntity({
    @Default('') String courseId,
    @Default('') String title,
    @Default('') String image,
  }) = _WeekRecapCourseEntity;
}

/// The four stamps, plus the day count the encouragement sentence is picked by.
@freezed
abstract class WeekRecapStatsEntity with _$WeekRecapStatsEntity {
  const factory WeekRecapStatsEntity({
    @Default(0) int activeDays,
    @Default(0) int streakDays,
    @Default(0) int habitsKept,
    @Default(0) int keypoints,
    @Default(0) int minutes,
  }) = _WeekRecapStatsEntity;
}

@freezed
abstract class WeekRecapEntity with _$WeekRecapEntity {
  const factory WeekRecapEntity({
    @Default('') String id,
    @Default(0) int weekNumber,
    required DateTime weekStart,
    required DateTime weekEnd,
    @Default(WeekRecapStatsEntity()) WeekRecapStatsEntity stats,
    @Default(<WeekRecapDayEntity>[]) List<WeekRecapDayEntity> days,
    @Default(<WeekRecapLessonEntity>[]) List<WeekRecapLessonEntity> lessons,
    @Default(<WeekRecapHabitEntity>[]) List<WeekRecapHabitEntity> habits,
    WeekRecapCourseEntity? favouriteCourse,
    DateTime? viewedAt,
    DateTime? dismissedAt,
  }) = _WeekRecapEntity;
}

/// A tile in the Sổ tay grid.
@freezed
abstract class WeekRecapSummaryEntity with _$WeekRecapSummaryEntity {
  const factory WeekRecapSummaryEntity({
    @Default('') String id,
    @Default(0) int weekNumber,
    required DateTime weekStart,
    required DateTime weekEnd,
  }) = _WeekRecapSummaryEntity;
}

/// `GET week-recap/current` — last week's poster, and whether the learner has
/// any recap at all.
@freezed
abstract class CurrentWeekRecapEntity with _$CurrentWeekRecapEntity {
  const factory CurrentWeekRecapEntity({
    WeekRecapEntity? recap,
    @Default(0) int archiveCount,
  }) = _CurrentWeekRecapEntity;
}

extension CurrentWeekRecapEntityX on CurrentWeekRecapEntity {
  /// The Monday popup: first open of every day, Monday through Sunday, until
  /// the week is actually VIEWED.
  ///
  /// The two stamps mean different things here. `viewedAt` ends the offers for
  /// good — the reader has seen their week. `dismissedAt` is "Để sau": it mutes
  /// the popup only for the calendar day it was pressed on, and the server
  /// moves that stamp on every press, so tomorrow's first open re-offers.
  ///
  /// An id-less recap is the in-progress debug preview — never something to
  /// offer, and there would be no id to stamp the answer against.
  bool get shouldShowPopup {
    final value = recap;
    if (value == null || value.id.isEmpty || value.viewedAt != null) return false;
    final dismissed = value.dismissedAt;

    return dismissed == null || !DateUtils.isSameDay(dismissed, DateTime.now());
  }

  /// The banner's "MỚI" pill: lit until the recap is VIEWED, and through the
  /// rest of the day it was viewed on; out from the next day to Sunday.
  ///
  /// Keyed on `viewedAt` alone — "Để sau" is not viewing, and a dismissal must
  /// not put the pill out while the week is still unseen.
  ///
  /// Local calendar days, not a duration: "today" is a calendar day to the
  /// reader, and a 24-hour window would keep the pill lit into tomorrow morning
  /// for anyone who opened their week in the evening.
  bool get isBannerNew {
    final value = recap;
    if (value == null) return false;
    final viewed = value.viewedAt;

    return viewed == null || DateUtils.isSameDay(viewed, DateTime.now());
  }

  bool get hasArchive => archiveCount > 0;
}
