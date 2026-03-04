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
  TaskEither<AppException, UserLearningStreakEntity> getUserLearningStreak(String id) {
    return callApiWithTransform<UserLearningStreakModel, UserLearningStreakEntity>(
      apiCall: () => _api.getUserLearningStreak(id),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheUserLearningStreak(data ?? UserLearningStreakModel()),
      onError: () async {
        final cachedModel = await _localDataSource.getCachedUserLearningStreak(id);
        return cachedModel?.toEntity();
      },
      defaultValue: UserLearningStreakEntity(),
    );
  }

  

  // ==================== HELPER METHODS ====================

  /// Converts UserLearningStreakEntity to JSON Map for API requests
  /// Provides flexibility to customize the request body structure without affecting domain models
  /// Reusable helper to avoid duplication in create/update methods
  Map<String, dynamic> _entityToJson(UserLearningStreakEntity entity) {
    return {
      'id': entity.id,
      'name': entity.name,
      // TODO: Add more fields as needed
    };
  }
  

  TaskEither<AppException, T> _missingDataSourceTask<T>(String operation) {
    
    return TaskEither.left(
      AppException.unexpected('$operation is not implemented. Please provide a remote or local data source.'),
    );
  }
}

