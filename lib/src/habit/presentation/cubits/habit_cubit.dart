part of '../../habit.dart';

enum AdoptHabitResult { success, slotFull, failure }

@lazySingleton
class HabitCubit extends Cubit<HabitState> with CubitUseCaseHandlerMixin<HabitState> {
  final GetHabitsUseCase _getHabitsUseCase;
  final GetUserHabitsSummaryUseCase _getSummaryUseCase;
  final AdoptHabitUseCase _adoptUseCase;
  final UpdateUserHabitUseCase _updateUseCase;
  final RemoveUserHabitUseCase _removeUseCase;
  final CheckInUserHabitUseCase _checkInUseCase;
  final GetHabitCheckinsUseCase _getCheckinsUseCase;
  final GetReanchorReasonsUseCase _getReanchorReasonsUseCase;
  final GetHabitConfigUseCase _getHabitConfigUseCase;
  final GetHabitScreenUseCase _getHabitScreenUseCase;
  final GetCachedHabitScreenUseCase _getCachedHabitScreenUseCase;
  final GetHabitPracticesUseCase _getHabitPracticesUseCase;
  final SubmitPracticeAttemptUseCase _submitPracticeAttemptUseCase;

  HabitCubit(
    this._getHabitsUseCase,
    this._getSummaryUseCase,
    this._adoptUseCase,
    this._updateUseCase,
    this._removeUseCase,
    this._checkInUseCase,
    this._getCheckinsUseCase,
    this._getReanchorReasonsUseCase,
    this._getHabitConfigUseCase,
    this._getHabitScreenUseCase,
    this._getCachedHabitScreenUseCase,
    this._getHabitPracticesUseCase,
    this._submitPracticeAttemptUseCase,
  ) : super(HabitState.initial());

  Future<void>? _ensureInFlight;

  /// When the last SUCCESSFUL network load landed. Drives the freshness guard in
  /// [ensureLoaded] (see [resolveHabitReloadAction]) so a confirmed-empty tab
  /// isn't refetched behind a spinner on every entry. Deliberately off the
  /// freezed state — it's a fetch bookkeeping detail, not UI state.
  DateTime? _lastLoadedAt;

  /// Analytics entry-point for the NEXT `habit_scr_view` (spec source set:
  /// nav_habit / home_banner / home_habit / habit_added_scr). Entry points set
  /// it right before navigating to the Habit tab; [HabitPage] consumes it when
  /// it logs the view. Defaults back to `nav_habit` after each read so a plain
  /// bottom-nav visit (which sets nothing) is reported correctly. Kept off the
  /// freezed state on purpose — it's transient routing metadata, not UI state.
  String _pendingScrSource = 'nav_habit';
  void setPendingScrSource(String source) => _pendingScrSource = source;
  String consumePendingScrSource() {
    final source = _pendingScrSource;
    _pendingScrSource = 'nav_habit';
    return source;
  }

  /// Wipe all per-user habit state on an account switch / logout. HabitCubit is
  /// a lazySingleton, so without this the next account (guest → login, or
  /// logout → next login) would keep the previous user's habits, summary, and
  /// re-anchor picks until a refetch overwrote them. Called from
  /// AuthBloc._resetAppCubits alongside the roadmap/progress resets. Clearing
  /// `_ensureInFlight` lets the next `ensureLoaded()` actually refetch.
  void reset() {
    _ensureInFlight = null;
    _lastLoadedAt = null;
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

  /// Loads the Habit tab's tracker + summary + slot cap in a single combined
  /// request (`GetHabitScreenUseCase` → `GET /user-habits/screen`), replacing
  /// three separate round trips.
  ///
  /// Cache-first (stale-while-revalidate): when nothing is in memory yet, the
  /// last cached screen is rendered immediately — no blank spinner on a warm
  /// start — before the network refresh resolves and reconciles it. Skipped
  /// once data is already in memory (pull-to-refresh, a second concurrent
  /// call) so a refresh never flashes stale cache over what's already shown.
  Future<void> load({bool showLoading = true}) async {
    var renderedFromCache = false;
    if (state.userHabits.isEmpty) {
      final cached = await _getCachedHabitScreenUseCase();
      if (cached != null && state.userHabits.isEmpty) {
        renderedFromCache = true;
        emit(
          state.copyWith(
            status: HabitPageStatus.success,
            userHabits: cached.habits,
            summary: cached.summary,
            freeActiveSlots: cached.freeActiveSlots,
          ),
        );
      }
    }

    await runUseCase<HabitScreenEntity>(
      usecase: () => _getHabitScreenUseCase(),
      // Only block on the spinner when there's genuinely nothing to show.
      // `renderedFromCache` covers the case the list check can't: a cache entry
      // that legitimately holds ZERO habits was still "empty", so a brand-new
      // user got a spinner over an answer we already had — show the empty state
      // straight away and let the refresh reconcile behind it. showLoading:
      // false (pull-to-refresh, app-resume, stale revalidation) never shows it,
      // keeping the current list visible mid-refresh.
      buildLoadingState: (showLoading && !renderedFromCache && state.userHabits.isEmpty) ? () => state.copyWith(status: HabitPageStatus.loading) : null,
      onFailure: (error) {
        // Keep already-shown (cached or in-memory) data on a failed refresh;
        // only surface the error state when there is nothing to fall back to.
        if (state.userHabits.isEmpty) {
          emit(state.copyWith(status: HabitPageStatus.failure, errorMessage: error));
        }
      },
      // A cluster's title reflects ONLY the re-anchor reason the user actually
      // picked — either stored on the habit at adopt time (h.reanchorReason)
      // or captured this session (reanchorReasonByCourse). We never backfill a
      // course's library reason, so a "why" the user didn't choose can't appear.
      onSuccess: (screen) {
        // Mark the moment a real fetch confirmed the screen — including a
        // confirmed-EMPTY one, which is what stops the refetch-on-every-entry.
        _lastLoadedAt = DateTime.now();
        emit(
          state.copyWith(
            status: HabitPageStatus.success,
            userHabits: screen.habits,
            summary: screen.summary,
            freeActiveSlots: screen.freeActiveSlots,
            errorMessage: null,
          ),
        );
      },
    );
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

  /// Self-heal for the Habit tab, safe to call on every page mount and tab
  /// return. [resolveHabitReloadAction] decides between three outcomes: block
  /// with a spinner (nothing loaded yet / previous attempt failed), do nothing
  /// (a recent load already confirmed the screen — including a confirmed-empty
  /// one), or revalidate silently once that load goes stale.
  Future<void> ensureLoaded() {
    final inFlight = _ensureInFlight;
    if (inFlight != null) return inFlight;
    final action = resolveHabitReloadAction(
      status: state.status,
      lastLoadedAt: _lastLoadedAt,
      now: DateTime.now(),
    );
    if (action == HabitReloadAction.none) return Future.value();
    final future = load(showLoading: action == HabitReloadAction.blocking).whenComplete(() => _ensureInFlight = null);
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

  /// Files a day's check-in. [method] records HOW it was filed — omit it for the
  /// quick 7-day-strip toggle, which the API reads as `tap`; the journal and
  /// quiz flows pass their own. [mood] is the journal's 3-level scale (1..3).
  Future<bool> checkIn(
    String userHabitId, {
    required bool done,
    String? note,
    HabitCheckinMethodEntity? method,
    int? mood,
    int? score,
  }) async {
    final result = await _checkInUseCase(
      userHabitId,
      done: done,
      note: note,
      method: method,
      mood: mood,
      score: score,
    ).run();
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

  /// Published practices for a library habit. Returns empty on failure so the
  /// picker simply offers journal only — the same thing it shows for a habit
  /// with no authored content, which is the common case today.
  Future<List<HabitPracticeEntity>> loadPractices(String habitId) async {
    if (habitId.isEmpty) return const [];
    final result = await _getHabitPracticesUseCase(habitId).run();
    return result.fold((_) => const [], (practices) => practices);
  }

  /// Finishes a practice. The server files the day's check-in in the same
  /// request, so this must NOT be paired with [checkIn] — two writes would race
  /// on the same `{userHabitId, date}` row.
  Future<bool> submitPracticeAttempt({
    required String userHabitId,
    required HabitCheckinMethodEntity method,
    String? learningItemId,
    List<Map<String, dynamic>>? exercisesResult,
    int? score,
    int? total,
    int? mood,
    String? note,
  }) async {
    final result = await _submitPracticeAttemptUseCase(
      userHabitId: userHabitId,
      method: method,
      learningItemId: learningItemId,
      exercisesResult: exercisesResult,
      score: score,
      total: total,
      mood: mood,
      note: note,
    ).run();

    return result.fold(
      (_) => false,
      (updated) {
        AppHaptic.success();
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
