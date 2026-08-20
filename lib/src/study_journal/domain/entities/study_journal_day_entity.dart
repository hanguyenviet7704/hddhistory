part of '../../study_journal.dart';

@freezed
abstract class StudyJournalItemEntity with _$StudyJournalItemEntity {
  const factory StudyJournalItemEntity({
    @Default('') String courseId,
    @Default('') String courseTitle,
    @Default('') String courseImage,
    @Default('') String lessonId,
    @Default('') String lessonTitle,
    @Default('') String keypointId,

    /// Headline of the row: the keypoint's title, or the lesson's when the
    /// keypoint has none (resolved server-side so both never disagree).
    @Default('') String title,
    @Default(0) int minutes,
    @Default(false) bool passed,
    DateTime? submittedAt,
  }) = _StudyJournalItemEntity;
}

@freezed
abstract class StudyJournalHabitEntity with _$StudyJournalHabitEntity {
  const factory StudyJournalHabitEntity({
    @Default('') String userHabitId,
    @Default('') String habitId,
    @Default('') String title,
    @Default('') String note,
  }) = _StudyJournalHabitEntity;
}

@freezed
abstract class StudyJournalDayDetailEntity with _$StudyJournalDayDetailEntity {
  const factory StudyJournalDayDetailEntity({
    required DateTime date,
    @Default(0) int minutes,
    @Default(<StudyJournalItemEntity>[]) List<StudyJournalItemEntity> lessons,
    @Default(<StudyJournalHabitEntity>[]) List<StudyJournalHabitEntity> habits,
  }) = _StudyJournalDayDetailEntity;
}

extension StudyJournalDayDetailEntityX on StudyJournalDayDetailEntity {
  /// A day with neither a lesson nor a habit — the design's "ngày nghỉ".
  bool get isEmpty => lessons.isEmpty && habits.isEmpty;
}
