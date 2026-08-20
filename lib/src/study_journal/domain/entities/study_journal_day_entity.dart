part of '../../study_journal.dart';

/// One course the learner touched that day: how many keypoints of it they
/// finished and how long those add up to.
@freezed
abstract class StudyJournalCourseEntity with _$StudyJournalCourseEntity {
  const factory StudyJournalCourseEntity({
    @Default('') String courseId,
    @Default('') String title,
    @Default('') String image,
    @Default(0) int lessons,
    @Default(0) int minutes,
  }) = _StudyJournalCourseEntity;
}

@freezed
abstract class StudyJournalHabitEntity with _$StudyJournalHabitEntity {
  const factory StudyJournalHabitEntity({
    @Default('') String userHabitId,
    @Default('') String habitId,
    @Default('') String title,
    @Default('') String image,
    @Default('') String note,
  }) = _StudyJournalHabitEntity;
}

@freezed
abstract class StudyJournalDayDetailEntity with _$StudyJournalDayDetailEntity {
  const factory StudyJournalDayDetailEntity({
    required DateTime date,

    /// Total keypoints finished that day — the same number the calendar square
    /// shades by, so the header and the square it was opened from agree.
    @Default(0) int lessons,
    @Default(0) int minutes,
    @Default(<StudyJournalCourseEntity>[]) List<StudyJournalCourseEntity> courses,
    @Default(<StudyJournalHabitEntity>[]) List<StudyJournalHabitEntity> habits,
  }) = _StudyJournalDayDetailEntity;
}

extension StudyJournalDayDetailEntityX on StudyJournalDayDetailEntity {
  /// A day with neither a lesson nor a habit — the design's "ngày nghỉ".
  bool get isEmpty => courses.isEmpty && habits.isEmpty;
}
