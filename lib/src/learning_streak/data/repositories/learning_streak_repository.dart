part of '../../learning_streak.dart';

@LazySingleton(as: ILearningStreakRepository)
class LearningStreakRepository with RestfulRequestHandlerMixin implements ILearningStreakRepository {
  final LearningStreakApi _api;
  final LearningStreakLocalDataSource _localDataSource;

  LearningStreakRepository(
    this._api,
    this._localDataSource,
  );

  @override
  TaskEither<AppException, UserLearningStreakEntity> getUserLearningStreak() {
    return callApiWithTransform<UserLearningStreakModel, UserLearningStreakEntity>(
      apiCall: () => _api.getUserLearningStreak(),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheUserLearningStreak(data ?? UserLearningStreakModel()),
      onError: () async {
        final cachedModel = await _localDataSource.getCachedUserLearningStreak();
        return cachedModel?.toEntity();
      },
      defaultValue: UserLearningStreakEntity(),
    );
  }
}

