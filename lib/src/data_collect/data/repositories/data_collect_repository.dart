part of '../../data_collect.dart';

@LazySingleton(as: IDataCollectRepository)
class DataCollectRepository with RestfulRequestHandlerMixin implements IDataCollectRepository {
  final DataCollectApi _api;
  final DataCollectLocalDataSource _localDataSource;

  DataCollectRepository(this._api, this._localDataSource);

  @override
  TaskEither<AppException, UserCollectDataEntity> getUserCollectData(String id) {
    return TaskEither.tryCatch(
      () async {
        try {
          // Try to get from API
          final model = await _api.getUserCollectData(id);
          // Cache the result
          await _localDataSource.cacheUserCollectData(model);
          return model.toEntity();
        } catch (e) {
          // If API fails, try to get from cache
          final cachedModel = await _localDataSource.getCachedUserCollectData(id);
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
  TaskEither<AppException, List<UserCollectDataEntity>> getAllUserCollectDatas() {
    return TaskEither.tryCatch(
      () async {
        try {
          // Try to get from API
          final models = await _api.getAllUserCollectDatas();
          // Cache the result
          await _localDataSource.cacheUserCollectDatas(models);
          return models.map((model) => model.toEntity()).toList();
        } catch (e) {
          // If API fails, try to get from cache
          final cachedModels = await _localDataSource.getCachedUserCollectDatas();
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
  TaskEither<AppException, UserCollectDataEntity> createUserCollectData(
    UserCollectDataEntity entity,
  ) {
    return TaskEither.tryCatch(
      () async {
        final model = UserCollectDataModel(
          id: entity.id,
          name: entity.name,
          createdAt: entity.createdAt,
          updatedAt: entity.updatedAt,
        );
        final result = await _api.createUserCollectData(model);
        // Cache the newly created item
        await _localDataSource.cacheUserCollectData(result);
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
  TaskEither<AppException, UserCollectDataEntity> updateUserCollectData(
    UserCollectDataEntity entity,
  ) {
    return TaskEither.tryCatch(
      () async {
        final model = UserCollectDataModel(
          id: entity.id,
          name: entity.name,
          createdAt: entity.createdAt,
          updatedAt: entity.updatedAt,
        );
        final result = await _api.updateUserCollectData(entity.id, model);
        // Update cache with the updated item
        await _localDataSource.cacheUserCollectData(result);
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
  TaskEither<AppException, Unit> deleteUserCollectData(String id) {
    return TaskEither.tryCatch(
      () async {
        await _api.deleteUserCollectData(id);
        // Remove from cache after successful deletion
        await _localDataSource.deleteCachedUserCollectData(id);
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
