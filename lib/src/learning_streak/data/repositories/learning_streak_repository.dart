part of '../../learning_streak.dart';

@LazySingleton(as: ILearningStreakRepository)
class LearningStreakRepository implements ILearningStreakRepository {
  final LearningStreakApi _api;
  final LearningStreakLocalDataSource _localDataSource;

  LearningStreakRepository(
    this._api,
    this._localDataSource,
  );

  @override
  TaskEither<AppException, StreakPopupConfigEntity> getStreakPopupConfig() {
    return TaskEither.tryCatch(
      () async {
        final response = await _api.getStreakPopupConfig();
        return (response.data ?? const StreakPopupConfigModel()).toEntity();
      },
      // No cache and no fallback entity here: the caller decides. Inventing a
      // default on failure would silently turn a server outage into "popup
      // enabled with the built-in delay", which is a behaviour change nobody
      // asked for.
      (error, stackTrace) => AppException.unexpected(error.toString()),
    );
  }

  @override
  TaskEither<AppException, LearningStreakFetchEntity> getUserLearningStreak(String userId) {
    return TaskEither.tryCatch(
      () async {
        final normalizedUserId = _normalizeUserId(userId);
        final isCacheableUser = normalizedUserId.isNotEmpty;

        try {
          final response = await _api.getUserLearningStreak();
          final remoteModel = (response.data ?? const UserLearningStreakModel()).sanitized();
          if (isCacheableUser && _isCurrentUser(normalizedUserId)) {
            await _localDataSource.cacheUserLearningStreak(normalizedUserId, remoteModel);
          }
          return LearningStreakFetchEntity(
            streak: remoteModel.toEntity(),
            origin: LearningStreakDataOrigin.remote,
          );
        } catch (error) {
          if (!isCacheableUser) rethrow;
          if (!_isCurrentUser(normalizedUserId)) rethrow;
          final cachedModel = await _localDataSource.getCachedUserLearningStreak(normalizedUserId);
          if (cachedModel != null) {
            return LearningStreakFetchEntity(
              streak: cachedModel.toEntity(),
              origin: LearningStreakDataOrigin.cache,
            );
          }
          rethrow;
        }
      },
      (error, stackTrace) {
        AppService.instance.appTrackingService.trackError(
          error,
          errorType: 'LearningStreakRepository.getUserLearningStreak',
          stackTrace: stackTrace,
        );
        if (error is AppException) return error;
        if (error is DioException) return AppException.fromDioException(error);
        return AppException.unexpected(error.toString());
      },
    );
  }

  @override
  TaskEither<AppException, UserLearningStreakEntity> checkInStreak(String userId) {
    return TaskEither.tryCatch(
      () async {
        final normalizedUserId = _normalizeUserId(userId);
        final response = await _api.checkInStreak();
        final model = (response.data ?? const UserLearningStreakModel()).sanitized();

        // Cache the post-check-in streak, not just remote reads: the week strip
        // must still show today ticked if the next launch is offline.
        if (normalizedUserId.isNotEmpty && _isCurrentUser(normalizedUserId)) {
          await _localDataSource.cacheUserLearningStreak(normalizedUserId, model);
        }

        return model.toEntity();
      },
      // No cache fallback on purpose, unlike the GET: a failed check-in means
      // the day was NOT recorded, and returning a cached streak would let the
      // caller latch the day as done and never retry.
      (error, stackTrace) {
        AppService.instance.appTrackingService.trackError(
          error,
          errorType: 'LearningStreakRepository.checkInStreak',
          stackTrace: stackTrace,
        );
        if (error is AppException) return error;
        if (error is DioException) return AppException.fromDioException(error);
        return AppException.unexpected(error.toString());
      },
    );
  }

  String _normalizeUserId(String userId) {
    return userId.trim();
  }

  bool _isCurrentUser(String requestedUserId) {
    if (!AppDI.injector.isRegistered<UserCubit>()) return true;
    final currentUserId = _normalizeUserId(AppDI.injector.get<UserCubit>().state.user.id);
    return currentUserId == requestedUserId;
  }
}
