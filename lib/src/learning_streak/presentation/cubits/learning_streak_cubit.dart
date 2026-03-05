part of '../../learning_streak.dart';

@lazySingleton
class LearningStreakCubit extends HydratedCubit<LearningStreakState> with CubitUseCaseHandlerMixin<LearningStreakState> {
  
  final GetUserLearningStreakUseCase _getUseCase;
  LearningStreakCubit(this._getUseCase) : super(LearningStreakState.initial());

  @override
  LearningStreakState fromJson(Map<String, dynamic> json) => LearningStreakState.fromJson(json);

  @override
  Map<String, dynamic> toJson(LearningStreakState state) => state.toJson();

  int _requestSerial = 0;

  void reset() => emit(LearningStreakState.initial());

  Future<LearningStreakRequestResult> loadUserLearningStreak({
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
