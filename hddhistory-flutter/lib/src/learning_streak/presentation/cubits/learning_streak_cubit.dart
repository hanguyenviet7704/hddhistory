part of '../../learning_streak.dart';

@lazySingleton
class LearningStreakCubit extends HydratedCubit<LearningStreakState> with CubitUseCaseHandlerMixin<LearningStreakState> {
  final GetUserLearningStreakUseCase _getUseCase;
  final CheckInStreakUseCase _checkInUseCase;
  LearningStreakCubit(this._getUseCase, this._checkInUseCase) : super(LearningStreakState.initial());

  /// Pinned so an obfuscated release build cannot rename the key this
  /// cubit's state is stored under — see [HydrateBlocService].
  @override
  String get storagePrefix => 'LearningStreakCubit';

  @override
  LearningStreakState fromJson(Map<String, dynamic> json) => LearningStreakState.fromJson(json);

  @override
  Map<String, dynamic> toJson(LearningStreakState state) => state.toJson();

  int _requestSerial = 0;

  // Home's own initState prefetches the streak (triggerSource: homeChip) a
  // few seconds before the streak popup page opens and calls this again with
  // identical params — without a guard that's a duplicate network round trip
  // for data that just landed. Scoped to ONLY the homeChip trigger: the other
  // callers (completionCta, from keypoint_complete_page/roleplay_feedback_page
  // /learning_streak_completion_gate) must always see the freshly-updated
  // streak right after a completion action, so they're never deduped here.
  DateTime? _lastHomeChipSuccessAt;
  String? _lastHomeChipUserId;
  Future<LearningStreakRequestResult>? _homeChipInFlight;
  static const _homeChipFreshnessWindow = Duration(seconds: 30);

  void reset() => emit(LearningStreakState.initial());

  void setLastStreakCountedDate(DateTime? date) => emit(state.copyWith(lastStreakCountedDate: date));
  bool isSameStreakCountedDay(DateTime date) => state.isSameStreakCountedDay(date);

  bool isSameCheckInDay(DateTime date) => state.isSameCheckInDay(date);

  /// Records today as a day the user showed up — the only thing that moves the
  /// streak now that finishing a lesson no longer does.
  ///
  /// The day latch is set ONLY on success, so a failed request is retried on the
  /// next tick instead of silently costing the user their day. On success the
  /// returned streak is emitted straight into state, which is what lets the
  /// toast show a week strip that already includes today.
  Future<bool> checkIn({required String requestedUserId}) async {
    final normalizedUserId = _normalizeUserId(requestedUserId);
    final result = await _checkInUseCase(normalizedUserId).run();

    return result.match(
      (error) {
        LogDev.warning('Streak check-in failed: ${error.message}');
        return false;
      },
      (streak) {
        emit(
          state.copyWith(
            status: LearningStreakStatus.success,
            selectedItem: streak,
            requestedUserId: normalizedUserId,
            dataOrigin: LearningStreakDataOrigin.remote,
            lastCheckInDate: StreakDay.today(),
            errorMessage: null,
          ),
        );
        // The home widget shows the same week strip, so keep it in step.
        HomeWidgetSyncTrigger.requestDebouncedSync();
        return true;
      },
    );
  }

  Future<LearningStreakRequestResult> loadUserLearningStreak({
    required LearningStreakTriggerSource triggerSource,
    required String requestedUserId,
    Duration timeout = const Duration(seconds: 2),
    bool emitLoading = true,
    bool allowSafeDefaultOnFailure = false,
  }) {
    if (triggerSource != LearningStreakTriggerSource.homeChip) {
      return _doLoadUserLearningStreak(
        triggerSource: triggerSource,
        requestedUserId: requestedUserId,
        timeout: timeout,
        emitLoading: emitLoading,
        allowSafeDefaultOnFailure: allowSafeDefaultOnFailure,
      );
    }

    final inFlight = _homeChipInFlight;
    if (inFlight != null) return inFlight;

    final normalizedUserId = _normalizeUserId(requestedUserId);
    final lastSuccessAt = _lastHomeChipSuccessAt;
    if (lastSuccessAt != null &&
        _lastHomeChipUserId == normalizedUserId &&
        state.status == LearningStreakStatus.success &&
        state.requestedUserId == normalizedUserId &&
        DateTime.now().difference(lastSuccessAt) < _homeChipFreshnessWindow) {
      return Future.value(
        LearningStreakRequestResult(
          requestId: state.requestId,
          requestedUserId: normalizedUserId,
          triggerSource: triggerSource,
          outcome: LearningStreakRequestOutcome.success,
          dataOrigin: state.dataOrigin,
          streak: state.selectedItem,
        ),
      );
    }

    final future =
        _doLoadUserLearningStreak(
              triggerSource: triggerSource,
              requestedUserId: requestedUserId,
              timeout: timeout,
              emitLoading: emitLoading,
              allowSafeDefaultOnFailure: allowSafeDefaultOnFailure,
            )
            .then((result) {
              if (result.isSuccess) {
                _lastHomeChipSuccessAt = DateTime.now();
                _lastHomeChipUserId = normalizedUserId;
              }
              return result;
            })
            .whenComplete(() => _homeChipInFlight = null);
    _homeChipInFlight = future;
    return future;
  }

  Future<LearningStreakRequestResult> _doLoadUserLearningStreak({
    required LearningStreakTriggerSource triggerSource,
    required String requestedUserId,
    Duration timeout = const Duration(seconds: 2),
    bool emitLoading = true,
    bool allowSafeDefaultOnFailure = false,
  }) async {
    final previousState = state;
    final normalizedUserId = _normalizeUserId(requestedUserId);
    final requestId = _nextRequestId();
    final requestSerial = _requestSerial;

    if (emitLoading) {
      emit(
        state.copyWith(
          status: LearningStreakStatus.loading,
          requestId: requestId,
          triggerSource: triggerSource,
          requestedUserId: normalizedUserId,
          errorMessage: null,
        ),
      );
    }

    final result = await _getUseCase(normalizedUserId).run().timeout(
      timeout,
      onTimeout: () => const Left<AppException, LearningStreakFetchEntity>(
        AppException.pending('learning_streak_timeout'),
      ),
    );

    if (!_isLatestRequest(requestSerial) || !_isCurrentUser(normalizedUserId)) {
      return LearningStreakRequestResult(
        requestId: requestId,
        requestedUserId: normalizedUserId,
        triggerSource: triggerSource,
        outcome: LearningStreakRequestOutcome.ignored,
        dataOrigin: LearningStreakDataOrigin.unknown,
        streak: state.selectedItem,
      );
    }

    return result.fold(
      (error) {
        if (allowSafeDefaultOnFailure) {
          final fallbackStreak = _resolveFailureFallbackStreak(
            previousState: previousState,
            requestedUserId: normalizedUserId,
          );
          final fallbackOrigin = _resolveFailureFallbackOrigin(
            previousState: previousState,
            requestedUserId: normalizedUserId,
          );
          emit(
            state.copyWith(
              status: LearningStreakStatus.success,
              selectedItem: fallbackStreak,
              requestId: requestId,
              triggerSource: triggerSource,
              requestedUserId: normalizedUserId,
              dataOrigin: fallbackOrigin,
              errorMessage: null,
            ),
          );
          return LearningStreakRequestResult(
            requestId: requestId,
            requestedUserId: normalizedUserId,
            triggerSource: triggerSource,
            outcome: LearningStreakRequestOutcome.success,
            dataOrigin: fallbackOrigin,
            streak: fallbackStreak,
          );
        }

        final isTimeout = error is PendingException || (error.message ?? '').contains('timeout');
        emit(
          state.copyWith(
            status: LearningStreakStatus.failure,
            requestId: requestId,
            triggerSource: triggerSource,
            requestedUserId: normalizedUserId,
            dataOrigin: LearningStreakDataOrigin.unknown,
            errorMessage: error.message,
          ),
        );
        return LearningStreakRequestResult(
          requestId: requestId,
          requestedUserId: normalizedUserId,
          triggerSource: triggerSource,
          outcome: isTimeout ? LearningStreakRequestOutcome.timeout : LearningStreakRequestOutcome.failure,
          dataOrigin: LearningStreakDataOrigin.unknown,
          streak: state.selectedItem,
          errorMessage: error.message,
        );
      },
      (fetch) {
        emit(
          state.copyWith(
            status: LearningStreakStatus.success,
            selectedItem: fetch.streak,
            requestId: requestId,
            triggerSource: triggerSource,
            requestedUserId: normalizedUserId,
            dataOrigin: fetch.origin,
            errorMessage: null,
          ),
        );
        if (fetch.origin == LearningStreakDataOrigin.remote) {
          HomeWidgetSyncTrigger.requestDebouncedSync();
        }
        return LearningStreakRequestResult(
          requestId: requestId,
          requestedUserId: normalizedUserId,
          triggerSource: triggerSource,
          outcome: LearningStreakRequestOutcome.success,
          dataOrigin: fetch.origin,
          streak: fetch.streak,
        );
      },
    );
  }

  String _nextRequestId() {
    _requestSerial += 1;
    return 'learning_streak_${DateTime.now().millisecondsSinceEpoch}_$_requestSerial';
  }

  bool _isLatestRequest(int requestSerial) => requestSerial == _requestSerial;

  bool _isCurrentUser(String requestedUserId) {
    if (!AppDI.injector.isRegistered<UserCubit>()) return true;
    final currentUserId = _normalizeUserId(AppDI.injector.get<UserCubit>().state.user.id);
    return currentUserId == requestedUserId;
  }

  String _normalizeUserId(String userId) {
    return userId.trim();
  }

  bool _canReusePreviousSuccess({
    required LearningStreakState previousState,
    required String requestedUserId,
  }) {
    return previousState.status == LearningStreakStatus.success && previousState.requestedUserId == requestedUserId && previousState.dataOrigin != LearningStreakDataOrigin.unknown;
  }

  UserLearningStreakEntity _resolveFailureFallbackStreak({
    required LearningStreakState previousState,
    required String requestedUserId,
  }) {
    if (_canReusePreviousSuccess(previousState: previousState, requestedUserId: requestedUserId)) {
      return previousState.selectedItem;
    }
    return const UserLearningStreakEntity();
  }

  LearningStreakDataOrigin _resolveFailureFallbackOrigin({
    required LearningStreakState previousState,
    required String requestedUserId,
  }) {
    if (_canReusePreviousSuccess(previousState: previousState, requestedUserId: requestedUserId)) {
      return previousState.dataOrigin;
    }
    return LearningStreakDataOrigin.safeDefault;
  }
}
