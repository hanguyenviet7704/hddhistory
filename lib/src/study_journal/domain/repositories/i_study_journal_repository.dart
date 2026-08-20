part of '../../study_journal.dart';

abstract interface class IStudyJournalRepository {
  /// One month of studied days. [month] is the first of the month; [tzOffset]
  /// is minutes east of UTC, so the server can split days on the learner's
  /// midnight instead of its own.
  TaskEither<AppException, StudyJournalMonthEntity> getMonth({
    required DateTime month,
    required int tzOffset,
  });

  TaskEither<AppException, StudyJournalDayDetailEntity> getDay({
    required DateTime day,
    required int tzOffset,
  });
}
