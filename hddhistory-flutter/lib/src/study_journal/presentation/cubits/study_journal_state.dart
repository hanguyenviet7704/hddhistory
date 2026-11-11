part of '../../study_journal.dart';

enum StudyJournalStatus { initial, loading, success, failure }

@freezed
abstract class StudyJournalState with _$StudyJournalState {
  const factory StudyJournalState({
    @Default(StudyJournalStatus.initial) StudyJournalStatus status,

    /// Month currently drawn, always the 1st at midnight local.
    DateTime? visibleMonth,

    /// Months already fetched, keyed by `YYYY-MM`. Kept so paging back and
    /// forth redraws instantly instead of re-fetching a month that cannot have
    /// changed since it was read a second ago.
    @Default(<String, StudyJournalMonthEntity>{}) Map<String, StudyJournalMonthEntity> months,
    String? errorMessage,
  }) = _StudyJournalState;

  factory StudyJournalState.initial() => const StudyJournalState();
}

extension StudyJournalStateX on StudyJournalState {
  StudyJournalMonthEntity? get currentMonth {
    final month = visibleMonth;
    if (month == null) return null;

    return months[formatStudyJournalMonth(month)];
  }

  /// Whether there is anything earlier to page to. False also while the first
  /// month is still loading: an arrow that is live before its own data landed
  /// invites a tap that resolves into an empty month.
  bool get canGoPrevious {
    final month = visibleMonth;
    final first = currentMonth?.firstActiveDate;
    if (month == null || first == null) return false;

    return DateTime(first.year, first.month).isBefore(month);
  }

  /// The future is not part of a journal — paging stops at the current month.
  bool get canGoNext {
    final month = visibleMonth;
    if (month == null) return false;
    final now = DateTime.now();

    return month.isBefore(DateTime(now.year, now.month));
  }
}
