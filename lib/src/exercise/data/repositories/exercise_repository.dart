part of '../../exercise.dart';

@LazySingleton(as: IExerciseRepository)
class ExerciseRepository with RestfulRequestHandlerMixin implements IExerciseRepository {
  final ExerciseApi _api;
  final ExerciseLocalDataSource _localDataSource;

  ExerciseRepository(this._api, this._localDataSource);

  @override
  TaskEither<AppException, ExerciseEntity> getExercise(String id) {
    return callApiWithTransform<ExerciseModel, ExerciseEntity>(
      apiCall: () => _api.getExercise(id),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheExercise(data ?? ExerciseModel()),
      onError: () async {
        final cachedModel = await _localDataSource.getCachedExercise(id);
        return cachedModel?.toEntity();
      },
      defaultValue: ExerciseEntity(),
    );
  }

  @override
  TaskEither<AppException, BasePageBreak<ExerciseEntity>> getAllExercises(
    PageBreakRequest request,
  ) {
    return callApiPageBreak<ExerciseModel, ExerciseEntity>(
      apiCall: () => _api.getAllExercises(request),
      transform: (model) => model.toEntity(),
      onSuccess: (pageData) async {
        // Cache only the items from the current page
        await _localDataSource.cacheExercises(pageData.items);
      },
      onError: () async {
        final cachedModels = await _localDataSource.getCachedExercises();
        if (cachedModels.isNotEmpty) {
          return BasePageBreak<ExerciseEntity>(
            currentPage: 1,
            totalPages: 1,
            itemsPerPage: cachedModels.length,
            items: cachedModels.map((model) => model.toEntity()).toList(),
          );
        }
        return null;
      },
    );
  }

  @override
  TaskEither<AppException, ExerciseEntity> createExercise(
    ExerciseEntity entity,
  ) {
    return callApiWithTransform<ExerciseModel, ExerciseEntity>(
      apiCall: () => _api.createExercise(_entityToJson(entity)),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheExercise(data ?? ExerciseModel()),
      defaultValue: ExerciseEntity(),
    );
  }

  @override
  TaskEither<AppException, ExerciseEntity> updateExercise(
    ExerciseEntity entity,
  ) {
    return callApiWithTransform<ExerciseModel, ExerciseEntity>(
      apiCall: () => _api.updateExercise(entity.id, _entityToJson(entity)),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheExercise(data ?? ExerciseModel()),
      defaultValue: ExerciseEntity(),
    );
  }

  @override
  TaskEither<AppException, Unit> deleteExercise(String id) {
    return executeApiAction(
      apiCall: () => _api.deleteExercise(id),
      onSuccess: () async => await _localDataSource.deleteCachedExercise(id),
    );
  }

  // ==================== HELPER METHODS ====================

  /// Converts ExerciseEntity to JSON Map for API requests
  /// Provides flexibility to customize the request body structure without affecting domain models
  /// Reusable helper to avoid duplication in create/update methods
  Map<String, dynamic> _entityToJson(ExerciseEntity entity) {
    return {
      'id': entity.id,
      'name': entity.name,
      // TODO: Add more fields as needed
    };
  }
}
