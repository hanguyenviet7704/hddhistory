part of '../../study_journal.dart';

/// One studied day, already parsed into the learner's own calendar.
@freezed
abstract class StudyJournalDayEntity with _$StudyJournalDayEntity {
  const factory StudyJournalDayEntity({
    required DateTime date,
    @Default(0) int keypoints,

    /// 0 = nothing studied, 1..4 = the four shades of the "Ít → Nhiều" legend.
    @Default(0) int level,
  }) = _StudyJournalDayEntity;
}

/// A month of the study journal.
@freezed
abstract class StudyJournalMonthEntity with _$StudyJournalMonthEntity {
  const factory StudyJournalMonthEntity({
    required DateTime month,

    /// Studied days keyed by `YYYY-MM-DD`; a missing key is an empty day.
    @Default(<String, StudyJournalDayEntity>{}) Map<String, StudyJournalDayEntity> days,
    @Default(0) int activeDays,
    @Default(0) int keypoints,

    /// The learner's first ever study day, or null when they have none yet.
    /// Everything before it is empty by definition, which is what stops the
    /// "previous month" arrow rather than letting it walk back forever.
    DateTime? firstActiveDate,
  }) = _StudyJournalMonthEntity;
}
