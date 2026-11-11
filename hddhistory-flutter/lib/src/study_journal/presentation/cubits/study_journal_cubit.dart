part of '../../study_journal.dart';

/// Drives the Profile screen's "Nhật ký học tập" calendar.
///
/// Deliberately NOT hydrated: the journal is a record of what happened, and a
/// cached month restored after a session of studying would show the learner a
/// square that is missing the work they just did.
@lazySingleton
class StudyJournalCubit extends Cubit<StudyJournalState> {
  final GetStudyJournalMonthUseCase _getMonthUseCase;
  final GetStudyJournalDayUseCase _getDayUseCase;

  StudyJournalCubit(this._getMonthUseCase, this._getDayUseCase) : super(StudyJournalState.initial());

  /// Minutes east of UTC — the same sign convention the API expects, so the
  /// server can cut days on the learner's midnight rather than its own.
  int get _tzOffset => DateTime.now().timeZoneOffset.inMinutes;

  /// Loads the current month unless a month is already on screen.
  ///
  /// Safe to call on every visit to Profile: it re-fetches the CURRENT month —
  /// studying happens between visits, and a cached copy would leave the squares
  /// the learner just earned missing until the app is killed — but leaves an
  /// already-open older month alone, so returning to the tab does not yank the
  /// calendar back to today. A month browsed back to is finished; nothing can
  /// land in it any more.
  Future<void> ensureLoaded() {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final month = state.visibleMonth ?? thisMonth;

    return loadMonth(month, force: month == thisMonth);
  }

  Future<void> loadMonth(DateTime month, {bool force = false}) async {
    final normalized = DateTime(month.year, month.month);
    final key = formatStudyJournalMonth(normalized);
    final cached = state.months[key];

    // Show the cached month immediately; a re-fetch behind it only ever adds
    // squares, so there is nothing to hide while it runs.
    emit(
      state.copyWith(
        visibleMonth: normalized,
        status: cached != null ? StudyJournalStatus.success : StudyJournalStatus.loading,
        errorMessage: null,
      ),
    );
    if (cached != null && !force) return;

    final result = await _getMonthUseCase(month: normalized, tzOffset: _tzOffset).run();
    result.match(
      (error) {
        if (isClosed) return;
        // A cached month stays on screen: replacing real squares with an error
        // because a refresh failed loses information the learner already had.
        emit(
          state.copyWith(
            status: cached != null ? StudyJournalStatus.success : StudyJournalStatus.failure,
            errorMessage: error.toString(),
          ),
        );
      },
      (data) {
        if (isClosed) return;
        emit(
          state.copyWith(
            status: StudyJournalStatus.success,
            months: {...state.months, key: data},
            errorMessage: null,
          ),
        );
      },
    );
  }

  Future<void> goPrevious() {
    final month = state.visibleMonth;
    if (month == null || !state.canGoPrevious) return Future.value();

    return loadMonth(DateTime(month.year, month.month - 1));
  }

  Future<void> goNext() {
    final month = state.visibleMonth;
    if (month == null || !state.canGoNext) return Future.value();

    return loadMonth(DateTime(month.year, month.month + 1));
  }

  /// One day's history for the tap-a-square sheet. Returns null on failure so
  /// the sheet can say so rather than sit on an empty list that reads as
  /// "nothing studied that day".
  Future<StudyJournalDayDetailEntity?> loadDay(DateTime day) async {
    final result = await _getDayUseCase(day: day, tzOffset: _tzOffset).run();

    return result.match((_) => null, (data) => data);
  }
}
