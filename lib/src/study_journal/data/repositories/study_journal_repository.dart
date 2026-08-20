part of '../../study_journal.dart';

@LazySingleton(as: IStudyJournalRepository)
class StudyJournalRepository implements IStudyJournalRepository {
  final StudyJournalApi _api;

  StudyJournalRepository(this._api);

  @override
  TaskEither<AppException, StudyJournalMonthEntity> getMonth({
    required DateTime month,
    required int tzOffset,
  }) {
    return TaskEither.tryCatch(
      () async {
        final response = await _api.getMonth(formatStudyJournalMonth(month), tzOffset);
        final model = response.data ?? const StudyJournalMonthModel();

        // The month the CALLER asked for wins over the one the server echoed:
        // the calendar draws its grid from this and a mismatch would render a
        // different month's squares under the current month's header.
        return model.toEntity().copyWith(month: DateTime(month.year, month.month));
      },
      (error, stackTrace) => AppException.unexpected(error.toString()),
    );
  }

  @override
  TaskEither<AppException, StudyJournalDayDetailEntity> getDay({
    required DateTime day,
    required int tzOffset,
  }) {
    return TaskEither.tryCatch(
      () async {
        final response = await _api.getDay(formatStudyJournalDate(day), tzOffset);
        final model = response.data ?? const StudyJournalDayDetailModel();

        return model.toEntity().copyWith(date: DateTime(day.year, day.month, day.day));
      },
      (error, stackTrace) => AppException.unexpected(error.toString()),
    );
  }
}

/// `YYYY-MM` / `YYYY-MM-DD` built from LOCAL parts.
///
/// Never `toIso8601String()`: that renders the UTC instant, so a learner in
/// Hanoi opening the app before 07:00 would ask the server for yesterday.
String formatStudyJournalMonth(DateTime month) => '${month.year.toString().padLeft(4, '0')}-${_two(month.month)}';

String formatStudyJournalDate(DateTime day) =>
    '${formatStudyJournalMonth(day)}-${_two(day.day)}';

String _two(int value) => value.toString().padLeft(2, '0');
