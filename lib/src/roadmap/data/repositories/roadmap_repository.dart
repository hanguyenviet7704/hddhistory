part of '../../roadmap.dart';

@LazySingleton(as: IRoadmapRepository)
class RoadmapRepository with RestfulRequestHandlerMixin implements IRoadmapRepository {
  final RoadmapApi _api;
  final RoadmapLocalDataSource _localDataSource;

  RoadmapRepository(this._api, this._localDataSource);

  @override
  TaskEither<AppException, RoadmapEntity> getRoadmap(String id) {
    return callApiWithTransform<RoadmapModel, RoadmapEntity>(
      apiCall: () => _api.getRoadmap(id),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheRoadmap(data ?? RoadmapModel()),
      onError: () async {
        final cachedModel = await _localDataSource.getCachedRoadmap(id);
        return cachedModel?.toEntity();
      },
      defaultValue: RoadmapEntity(),
    );
  }

  @override
  TaskEither<AppException, BasePageBreak<RoadmapEntity>> getAllRoadmaps(
    PageBreakRequest request,
  ) {
    return callApiPageBreak<RoadmapModel, RoadmapEntity>(
      apiCall: () => _api.getAllRoadmaps(request),
      transform: (model) => model.toEntity(),
      onSuccess: (pageData) async {
        // Cache only the items from the current page
        await _localDataSource.cacheRoadmaps(pageData.items);
      },
      onError: () async {
        final cachedModels = await _localDataSource.getCachedRoadmaps();
        if (cachedModels.isNotEmpty) {
          return BasePageBreak<RoadmapEntity>(
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
  TaskEither<AppException, RoadmapEntity> createRoadmap(
    RoadmapEntity entity,
  ) {
    return callApiWithTransform<RoadmapModel, RoadmapEntity>(
      apiCall: () => _api.createRoadmap(_entityToJson(entity)),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheRoadmap(data ?? RoadmapModel()),
      defaultValue: RoadmapEntity(),
    );
  }

  @override
  TaskEither<AppException, RoadmapEntity> updateRoadmap(
    RoadmapEntity entity,
  ) {
    return callApiWithTransform<RoadmapModel, RoadmapEntity>(
      apiCall: () => _api.updateRoadmap(entity.id, _entityToJson(entity)),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheRoadmap(data ?? RoadmapModel()),
      defaultValue: RoadmapEntity(),
    );
  }

  @override
  TaskEither<AppException, Unit> deleteRoadmap(String id) {
    return executeApiAction(
      apiCall: () => _api.deleteRoadmap(id),
      onSuccess: () async => await _localDataSource.deleteCachedRoadmap(id),
    );
  }

  // ==================== HELPER METHODS ====================

  /// Converts RoadmapEntity to JSON Map for API requests
  /// Provides flexibility to customize the request body structure without affecting domain models
  /// Reusable helper to avoid duplication in create/update methods
  Map<String, dynamic> _entityToJson(RoadmapEntity entity) {
    return {
      'id': entity.id,
      'name': entity.name,
      // TODO: Add more fields as needed
    };
  }
}
