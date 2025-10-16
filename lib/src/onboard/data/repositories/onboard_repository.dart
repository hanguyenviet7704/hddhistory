part of '../../onboard.dart';

@LazySingleton(as: IOnboardRepository)
class OnboardRepository with RestfulRequestHandlerMixin implements IOnboardRepository {
  final OnboardApi _api;
  final OnboardLocalDataSource _localDataSource;

  OnboardRepository(this._api, this._localDataSource);

  @override
  TaskEither<AppException, OnboardEntity> getOnboard(String id) {
    return TaskEither.tryCatch(
      () async {
        try {
          // Try to get from API
          final model = await _api.getOnboard(id);
          // Cache the result
          await _localDataSource.cacheOnboard(model);
          return model.toEntity();
        } catch (e) {
          // If API fails, try to get from cache
          final cachedModel = await _localDataSource.getCachedOnboard(id);
          if (cachedModel != null) {
            return cachedModel.toEntity();
          }
          rethrow;
        }
      },
      (error, stackTrace) {
        if (error is DioException) {
          return AppException.fromDioException(error);
        }
        return AppException.unexpected(error.toString());
      },
    );
  }

  @override
  TaskEither<AppException, List<OnboardEntity>> getAllOnboards() {
    return TaskEither.tryCatch(
      () async {
        try {
          // Try to get from API
          final models = await _api.getAllOnboards();
          // Cache the result
          await _localDataSource.cacheOnboards(models);
          return models.map((model) => model.toEntity()).toList();
        } catch (e) {
          // If API fails, try to get from cache
          final cachedModels = await _localDataSource.getCachedOnboards();
          if (cachedModels.isNotEmpty) {
            return cachedModels.map((model) => model.toEntity()).toList();
          }
          rethrow;
        }
      },
      (error, stackTrace) {
        if (error is DioException) {
          return AppException.fromDioException(error);
        }
        return AppException.unexpected(error.toString());
      },
    );
  }

  @override
  TaskEither<AppException, OnboardEntity> createOnboard(
    OnboardEntity entity,
  ) {
    return TaskEither.tryCatch(
      () async {
        final model = OnboardModel(
          id: entity.id,
          isNativeEnglishSpeaker: entity.isNativeEnglishSpeaker,
          comfortableLearningTime: entity.comfortableLearningTime,
          dailyLearningGoal: entity.dailyLearningGoal,
          timeToBecomeSkilled: entity.timeToBecomeSkilled,
          topicsWantToMaster: entity.topicsWantToMaster
              .map(
                (e) => OnboardOptionModel(
                  isNativeEnglishSpeaker: e.isNativeEnglishSpeaker,
                  comfortableLearningTime: e.comfortableLearningTime,
                  dailyLearningGoal: e.dailyLearningGoal,
                  timeToBecomeSkilled: e.timeToBecomeSkilled,
                ),
              )
              .toList(),
          seemLikeYou: entity.seemLikeYou
              .map(
                (e) => OnboardOptionModel(
                  isNativeEnglishSpeaker: e.isNativeEnglishSpeaker,
                  comfortableLearningTime: e.comfortableLearningTime,
                  dailyLearningGoal: e.dailyLearningGoal,
                  timeToBecomeSkilled: e.timeToBecomeSkilled,
                ),
              )
              .toList(),
          strugglesWhenSpeaking: entity.strugglesWhenSpeaking
              .map(
                (e) => OnboardOptionModel(
                  isNativeEnglishSpeaker: e.isNativeEnglishSpeaker,
                  comfortableLearningTime: e.comfortableLearningTime,
                  dailyLearningGoal: e.dailyLearningGoal,
                  timeToBecomeSkilled: e.timeToBecomeSkilled,
                ),
              )
              .toList(),
        );
        final result = await _api.createOnboard(model);
        // Cache the newly created item
        await _localDataSource.cacheOnboard(result);
        return result.toEntity();
      },
      (error, stackTrace) {
        if (error is DioException) {
          return AppException.fromDioException(error);
        }
        return AppException.unexpected(error.toString());
      },
    );
  }

  @override
  TaskEither<AppException, OnboardEntity> updateOnboard(
    OnboardEntity entity,
  ) {
    return TaskEither.tryCatch(
      () async {
        final model = OnboardModel(
          id: entity.id,
          isNativeEnglishSpeaker: entity.isNativeEnglishSpeaker,
          comfortableLearningTime: entity.comfortableLearningTime,
          dailyLearningGoal: entity.dailyLearningGoal,
          timeToBecomeSkilled: entity.timeToBecomeSkilled,
          topicsWantToMaster: entity.topicsWantToMaster
              .map(
                (e) => OnboardOptionModel(
                  isNativeEnglishSpeaker: e.isNativeEnglishSpeaker,
                  comfortableLearningTime: e.comfortableLearningTime,
                  dailyLearningGoal: e.dailyLearningGoal,
                  timeToBecomeSkilled: e.timeToBecomeSkilled,
                ),
              )
              .toList(),
          seemLikeYou: entity.seemLikeYou
              .map(
                (e) => OnboardOptionModel(
                  isNativeEnglishSpeaker: e.isNativeEnglishSpeaker,
                  comfortableLearningTime: e.comfortableLearningTime,
                  dailyLearningGoal: e.dailyLearningGoal,
                  timeToBecomeSkilled: e.timeToBecomeSkilled,
                ),
              )
              .toList(),
          strugglesWhenSpeaking: entity.strugglesWhenSpeaking
              .map(
                (e) => OnboardOptionModel(
                  isNativeEnglishSpeaker: e.isNativeEnglishSpeaker,
                  comfortableLearningTime: e.comfortableLearningTime,
                  dailyLearningGoal: e.dailyLearningGoal,
                  timeToBecomeSkilled: e.timeToBecomeSkilled,
                ),
              )
              .toList(),
        );
        final result = await _api.updateOnboard(entity.id, model);
        // Update cache with the updated item
        await _localDataSource.cacheOnboard(result);
        return result.toEntity();
      },
      (error, stackTrace) {
        if (error is DioException) {
          return AppException.fromDioException(error);
        }
        return AppException.unexpected(error.toString());
      },
    );
  }

  @override
  TaskEither<AppException, Unit> deleteOnboard(String id) {
    return TaskEither.tryCatch(
      () async {
        await _api.deleteOnboard(id);
        // Remove from cache after successful deletion
        await _localDataSource.deleteCachedOnboard(id);
        return unit;
      },
      (error, stackTrace) {
        if (error is DioException) {
          return AppException.fromDioException(error);
        }
        return AppException.unexpected(error.toString());
      },
    );
  }
}
