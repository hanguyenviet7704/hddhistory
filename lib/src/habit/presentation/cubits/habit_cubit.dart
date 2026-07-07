part of '../../habit.dart';

enum AdoptHabitResult { success, slotFull, failure }

@lazySingleton
class HabitCubit extends Cubit<HabitState> with CubitUseCaseHandlerMixin<HabitState> {
  final GetHabitsUseCase _getHabitsUseCase;
  final GetUserHabitsUseCase _getUserHabitsUseCase;
  final GetUserHabitsSummaryUseCase _getSummaryUseCase;
  final AdoptHabitUseCase _adoptUseCase;
  final UpdateUserHabitUseCase _updateUseCase;
  final RemoveUserHabitUseCase _removeUseCase;
  final CheckInUserHabitUseCase _checkInUseCase;
  final GetHabitCheckinsUseCase _getCheckinsUseCase;
  final GetReanchorReasonsUseCase _getReanchorReasonsUseCase;

  HabitCubit(
    this._getHabitsUseCase,
    this._getUserHabitsUseCase,
    this._getSummaryUseCase,
    this._adoptUseCase,
    this._updateUseCase,
    this._removeUseCase,
    this._checkInUseCase,
    this._getCheckinsUseCase,
    this._getReanchorReasonsUseCase,
  ) : super(HabitState.initial());

  Future<void>? _ensureInFlight;

  void setToggle(HabitTabToggle toggle) => emit(state.copyWith(toggle: toggle));

  /// Hide the Home check-in reminder card for the rest of today (§9.4 FR4.4).
  void dismissHomeReminderToday() => emit(state.copyWith(homeReminderDismissedOn: DateTime.now()));

  /// Mark the Sunday Weekly recap as shown today so it doesn't re-open (§9.9).
  void markWeeklyRecapShown() => emit(state.copyWith(weeklyRecapShownOn: DateTime.now()));

  /// Mark a course's Re-anchor as shown so it appears at most once (§9.1).
  void markReanchorShown(String courseId) =>
      emit(state.copyWith(reanchorShownCourseIds: {...state.reanchorShownCourseIds, courseId}));

  Future<void> load({bool showLoading = true}) async {
    await runUseCaseList<UserHabitEntity>(
      usecase: () => _getUserHabitsUseCase(),
      buildLoadingState: showLoading ? () => state.copyWith(status: HabitPageStatus.loading) : null,
      onFailure: (error) => emit(state.copyWith(status: HabitPageStatus.failure, errorMessage: error)),
      onSuccess: (userHabits) => emit(state.copyWith(status: HabitPageStatus.success, userHabits: userHabits, errorMessage: null)),
    );
    unawaited(loadSummary());
  }

  Future<void> loadSummary() async {
    await runUseCase<UserHabitSummaryEntity>(
      usecase: () => _getSummaryUseCase(),
      onFailure: (_) {},
      onSuccess: (summary) => emit(state.copyWith(summary: summary)),
    );
  }

  /// Self-heal for the Habit tab: refetches when nothing is loaded yet (a
  /// failed/skipped first load) or the tab is genuinely empty (new user who
  /// hasn't adopted a habit — this also refetches, an accepted trade-off,
  /// mirroring [shouldSelfHealHomeData]). No-op mid-load, so it's safe to
  /// call on every page mount and tab return.
  Future<void> ensureLoaded() {
    final inFlight = _ensureInFlight;
    if (inFlight != null) return inFlight;
    if (!shouldEnsureHabitsReload(state)) return Future.value();
    final future = load().whenComplete(() => _ensureInFlight = null);
    _ensureInFlight = future;
    return future;
  }

  /// Published habit library. Pass [lessonId] for the per-lesson reflection
  /// suggestions (§9.2); omit for the whole library.
  Future<List<HabitEntity>> loadLibrary({String? lessonId}) async {
    final result = await _getHabitsUseCase(lessonId: lessonId).run();
    return result.fold((_) => const [], (habits) => habits);
  }

  /// A library habit the user hasn't adopted yet — the "NEW HABIT" offered by
  /// the post-lesson upgrade prompt (flowchart). Null if the library is
  /// exhausted or unreachable.
  Future<HabitEntity?> suggestNewHabit() async {
    final library = await loadLibrary();
    if (library.isEmpty) return null;
    final adoptedIds = state.userHabits.map((h) => h.habitId).toSet();
    return library.where((h) => !adoptedIds.contains(h.id)).firstOrNull;
  }

  bool _isSlotFullError(AppException exception) {
    if (exception is! FromDioException) return false;
    final data = exception.error.response?.data;
    if (data is Map && data['code'] == 'SLOT_FULL') return true;
    return exception.error.response?.statusCode == 409;
  }

  Future<AdoptHabitResult> adopt({
    required String habitId,
    String? reminderTime,
    required int packLength,
    String? sourceLessonId,
    String? sourceCourseId,
  }) async {
    final result = await _adoptUseCase(
      habitId: habitId,
      reminderTime: reminderTime,
      packLength: packLength,
      sourceLessonId: sourceLessonId,
      sourceCourseId: sourceCourseId,
    ).run();
    return result.fold(
      (exception) => _isSlotFullError(exception) ? AdoptHabitResult.slotFull : AdoptHabitResult.failure,
      (userHabit) {
        emit(state.copyWith(userHabits: [...state.userHabits, userHabit]));
        unawaited(loadSummary());
        unawaited(scheduleHabitReminder(userHabit));
        return AdoptHabitResult.success;
      },
    );
  }

  /// Activating (resuming a paused habit) can also hit the slot limit, so
  /// this returns the same result type as [adopt].
  Future<AdoptHabitResult> setActive(String userHabitId, bool active) async {
    final result = await _updateUseCase(
      userHabitId,
      state: active ? UserHabitStateEntity.active : UserHabitStateEntity.draft,
    ).run();

    return result.fold(
      (exception) => _isSlotFullError(exception) ? AdoptHabitResult.slotFull : AdoptHabitResult.failure,
      (updated) {
        _replaceUserHabit(updated);
        unawaited(loadSummary());
        if (active) {
          unawaited(scheduleHabitReminder(updated));
        } else {
          unawaited(cancelHabitReminder(userHabitId));
        }
        return AdoptHabitResult.success;
      },
    );
  }

  Future<bool> remove(String userHabitId) async {
    final result = await _removeUseCase(userHabitId).run();
    return result.fold(
      (_) => false,
      (_) {
        emit(state.copyWith(userHabits: state.userHabits.where((h) => h.id != userHabitId).toList()));
        unawaited(loadSummary());
        unawaited(cancelHabitReminder(userHabitId));
        return true;
      },
    );
  }

  /// Recommit an existing habit to a new pack length (post-lesson summary's
  /// "How far this time?" — design.md 5.4). Does not touch the slot limit
  /// (packLength changes never affect active/draft state).
  Future<bool> setPackLength(String userHabitId, int packLength) async {
    final result = await _updateUseCase(userHabitId, packLength: packLength).run();
    return result.fold(
      (_) => false,
      (updated) {
        _replaceUserHabit(updated);
        return true;
      },
    );
  }

  Future<bool> checkIn(String userHabitId, {required bool done, String? note}) async {
    final result = await _checkInUseCase(userHabitId, done: done, note: note).run();
    return result.fold(
      (_) => false,
      (updated) {
        _replaceUserHabit(updated);
        unawaited(loadSummary());
        return true;
      },
    );
  }

  /// Full check-in log for one habit — powers the Habit-detail monthly heatmap
  /// and diary list (§9.8). Returns empty on failure (screen shows empty state).
  Future<List<HabitCheckinEntity>> getCheckins(String userHabitId) async {
    final result = await _getCheckinsUseCase(userHabitId).run();
    return result.fold((_) => const [], (checkins) => checkins);
  }

  /// BTV-authored re-anchor reasons for a course (§9.1). Empty when none
  /// configured — the caller then skips the Re-anchor screen entirely.
  Future<List<ReanchorReasonEntity>> getReanchorReasons(String courseId) async {
    final result = await _getReanchorReasonsUseCase(courseId).run();
    return result.fold((_) => const [], (reasons) => reasons);
  }

  void _replaceUserHabit(UserHabitEntity updated) {
    emit(
      state.copyWith(
        userHabits: state.userHabits.map((h) => h.id == updated.id ? updated : h).toList(),
      ),
    );
  }
}
