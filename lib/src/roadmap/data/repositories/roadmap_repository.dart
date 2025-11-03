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
      'courseId': entity.courseId,
      'node': entity.node
          .map(
            (e) => {
              'id': e.id,
              'title': e.title.toJson(),
              'entranceId': e.entranceId,
              'lessonIds': e.lessonIds,
              'outputId': e.outputId,
              'entrance': {
                'id': e.entrance.id,
                'courseId': e.entrance.courseId,
                'type': e.entrance.type.name,
                'title': e.entrance.title.toJson(),
                'description': e.entrance.description.toJson(),
                'image': e.entrance.image,
                'status': e.entrance.status.name,
                'keypoints': e.entrance.keypoints,
                'estimateCompleTime': e.entrance.estimateCompleTime.toJson(),
                'icon': e.entrance.icon,
                'index': e.entrance.index,
              },
              'lessons': e.lessons
                  .map(
                    (lesson) => {
                      'id': lesson.id,
                      'courseId': lesson.courseId,
                      'type': lesson.type.name,
                      'title': lesson.title.toJson(),
                      'description': lesson.description.toJson(),
                      'image': lesson.image,
                      'status': lesson.status.name,
                      'keypoints': lesson.keypoints,
                      'estimateCompleTime': lesson.estimateCompleTime.toJson(),
                      'icon': lesson.icon,
                      'index': lesson.index,
                    },
                  )
                  .toList(),
              'output': {
                'id': e.output.id,
                'courseId': e.output.courseId,
                'type': e.output.type.name,
                'title': e.output.title.toJson(),
                'description': e.output.description.toJson(),
                'image': e.output.image,
                'status': e.output.status.name,
                'keypoints': e.output.keypoints,
                'estimateCompleTime': e.output.estimateCompleTime.toJson(),
                'icon': e.output.icon,
                'index': e.output.index,
              },
            },
          )
          .toList(),
      'lessonList': entity.lessonList
          .map(
            (lesson) => {
              'id': lesson.id,
              'courseId': lesson.courseId,
              'type': lesson.type.name,
              'title': lesson.title.toJson(),
              'description': lesson.description.toJson(),
              'image': lesson.image,
              'status': lesson.status.name,
              'keypoints': lesson.keypoints,
              'estimateCompleTime': lesson.estimateCompleTime.toJson(),
              'icon': lesson.icon,
              'index': lesson.index,
            },
          )
          .toList(),
      'createdAt': entity.createdAt?.toIso8601String(),
      'updatedAt': entity.updatedAt?.toIso8601String(),
    };
  }
}
