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
  final GetHabitConfigUseCase _getHabitConfigUseCase;

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
    this._getHabitConfigUseCase,
  ) : super(HabitState.initial());

  Future<void>? _ensureInFlight;

  /// Wipe all per-user habit state on an account switch / logout. HabitCubit is
  /// a lazySingleton, so without this the next account (guest → login, or
  /// logout → next login) would keep the previous user's habits, summary, and
  /// re-anchor picks until a refetch overwrote them. Called from
  /// AuthBloc._resetAppCubits alongside the roadmap/progress resets. Clearing
  /// `_ensureInFlight` lets the next `ensureLoaded()` actually refetch.
  void reset() {
    _ensureInFlight = null;
    emit(HabitState.initial());
  }

  void setToggle(HabitTabToggle toggle) => emit(state.copyWith(toggle: toggle));

  /// Hide the Home check-in reminder card for the rest of today (§9.4 FR4.4).
  void dismissHomeReminderToday() => emit(state.copyWith(homeReminderDismissedOn: DateTime.now()));

  /// Mark the Weekly recap as shown for this week so it doesn't re-open (§9.9).
  /// Records both the server week start (preferred dedup key) and the device
  /// day (legacy fallback for when the server didn't supply a week start).
  void markWeeklyRecapShown() => emit(
    state.copyWith(
      weeklyRecapShownOn: DateTime.now(),
      weeklyRecapShownWeekStart: state.summary.weekStartDate,
    ),
  );

  /// Mark a course's Re-anchor as shown so it appears at most once (§9.1).
  void markReanchorShown(String courseId) => emit(state.copyWith(reanchorShownCourseIds: {...state.reanchorShownCourseIds, courseId}));

  /// Remember the re-anchor reason the user picked for a course (§9.5), so it
  /// can be attached when a habit is later adopted from that course's keypoint
  /// and shown as the tracker cluster title.
  void setReanchorReason(String courseId, ReanchorReasonEntity reason) {
    if (courseId.isEmpty) return;
    emit(state.copyWith(reanchorReasonByCourse: {...state.reanchorReasonByCourse, courseId: reason}));
  }

  Future<void> load({bool showLoading = true}) async {
    if (showLoading) emit(state.copyWith(status: HabitPageStatus.loading));
    final result = await _getUserHabitsUseCase().run();
    result.fold(
      (exception) => emit(state.copyWith(status: HabitPageStatus.failure, errorMessage: exception.toString())),
      // A cluster's title reflects ONLY the re-anchor reason the user actually
      // picked — either stored on the habit at adopt time (h.reanchorReason)
      // or captured this session (reanchorReasonByCourse). We never backfill a
      // course's library reason, so a "why" the user didn't choose can't appear.
      (userHabits) => emit(state.copyWith(status: HabitPageStatus.success, userHabits: userHabits, errorMessage: null)),
    );
    unawaited(loadSummary());
    unawaited(loadFreeSlots());
  }

  /// Refresh the admin-configured free slot cap; on failure keep the current
  /// (default) value — the server still enforces the real limit.
  Future<void> loadFreeSlots() async {
    final result = await _getHabitConfigUseCase().run();
    result.fold(
      (_) {},
      (slots) => emit(state.copyWith(freeActiveSlots: slots)),
    );
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

  /// Published habit library. Pass [keypointId] for the per-keypoint
  /// reflection suggestions (§9.2); omit for the whole library.
  Future<List<HabitEntity>> loadLibrary({String? keypointId}) async {
    final result = await _getHabitsUseCase(keypointId: keypointId).run();
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
    String? sourceKeypointId,
    String? sourceCourseId,
  }) async {
    // Attach the re-anchor reason the user picked for this course (if any), so
    // the tracker can label the habit's cluster with it (§9.5).
    final picked = (sourceCourseId != null && sourceCourseId.isNotEmpty) ? state.reanchorReasonByCourse[sourceCourseId] : null;
    final result = await _adoptUseCase(
      habitId: habitId,
      reminderTime: reminderTime,
      packLength: packLength,
      sourceKeypointId: sourceKeypointId,
      sourceCourseId: sourceCourseId,
      reanchorReasonId: picked?.id,
      reanchorReason: picked?.reason,
    ).run();
    return result.fold(
      (exception) => _isSlotFullError(exception) ? AdoptHabitResult.slotFull : AdoptHabitResult.failure,
      (userHabit) {
        AppHaptic.success();
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
        if (done) AppHaptic.success();
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

  // Memoised per course so a prefetch (kicked off in parallel with the roadmap
  // fetch — see CourseRoadmapCubit.loadRoadmap) is reused instantly by
  // _maybeShowReanchor, letting the prompt open the moment the roadmap lands
  // instead of after a second round-trip.
  final Map<String, List<ReanchorReasonEntity>> _reanchorReasonsCache = {};

  /// BTV-authored re-anchor reasons for a course (§9.1). Empty when none
  /// configured — the caller then skips the Re-anchor screen entirely.
  Future<List<ReanchorReasonEntity>> getReanchorReasons(String courseId) async {
    final cached = _reanchorReasonsCache[courseId];
    if (cached != null) return cached;
    final result = await _getReanchorReasonsUseCase(courseId).run();
    final reasons = result.fold((_) => const <ReanchorReasonEntity>[], (reasons) => reasons);
    _reanchorReasonsCache[courseId] = reasons;
    return reasons;
  }

  void _replaceUserHabit(UserHabitEntity updated) {
    emit(
      state.copyWith(
        userHabits: state.userHabits.map((h) => h.id == updated.id ? updated : h).toList(),
      ),
    );
  }
}
