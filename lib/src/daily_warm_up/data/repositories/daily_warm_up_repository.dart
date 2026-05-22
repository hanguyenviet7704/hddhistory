part of '../../daily_warm_up.dart';

@LazySingleton(as: IDailyWarmUpRepository)
class DailyWarmUpRepository with RestfulRequestHandlerMixin implements IDailyWarmUpRepository {
  final DailyWarmUpApi _api;
  final DailyWarmUpLocalDataSource _localDataSource;
  

  DailyWarmUpRepository(
    this._api,
    this._localDataSource,
  );

  @override
  TaskEither<AppException, DailyWarmUpEntity> getDailyWarmUp(String id) {
    return callApiWithTransform<DailyWarmUpModel, DailyWarmUpEntity>(
      apiCall: () => _api.getDailyWarmUp(id),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheDailyWarmUp(data ?? DailyWarmUpModel()),
      onError: () async {
        final cachedModel = await _localDataSource.getCachedDailyWarmUp(id);
        return cachedModel?.toEntity();
      },
      defaultValue: DailyWarmUpEntity(),
    );
  }

  

  // ==================== HELPER METHODS ====================

  /// Converts DailyWarmUpEntity to JSON Map for API requests
  /// Provides flexibility to customize the request body structure without affecting domain models
  /// Reusable helper to avoid duplication in create/update methods
  Map<String, dynamic> _entityToJson(DailyWarmUpEntity entity) {
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

