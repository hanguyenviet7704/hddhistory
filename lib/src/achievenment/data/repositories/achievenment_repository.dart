part of '../../achievenment.dart';

@LazySingleton(as: IAchievenmentRepository)
class AchievenmentRepository with RestfulRequestHandlerMixin implements IAchievenmentRepository {
  final AchievenmentApi _api;
  final AchievenmentLocalDataSource _localDataSource;
  

  AchievenmentRepository(
    this._api,
    this._localDataSource,
  );

  @override
  TaskEither<AppException, AchievenmentResponseEntity> getAchievenmentResponse(String id) {
    return callApiWithTransform<AchievenmentResponseModel, AchievenmentResponseEntity>(
      apiCall: () => _api.getAchievenmentResponse(id),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheAchievenmentResponse(data ?? AchievenmentResponseModel()),
      onError: () async {
        final cachedModel = await _localDataSource.getCachedAchievenmentResponse(id);
        return cachedModel?.toEntity();
      },
      defaultValue: AchievenmentResponseEntity(),
    );
  }

  

  // ==================== HELPER METHODS ====================

  /// Converts AchievenmentResponseEntity to JSON Map for API requests
  /// Provides flexibility to customize the request body structure without affecting domain models
  /// Reusable helper to avoid duplication in create/update methods
  Map<String, dynamic> _entityToJson(AchievenmentResponseEntity entity) {
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

