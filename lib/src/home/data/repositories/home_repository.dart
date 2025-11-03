part of '../../home.dart';

@LazySingleton(as: IHomeRepository)
class HomeRepository with RestfulRequestHandlerMixin implements IHomeRepository {
  final HomeApi _api;
  final HomeLocalDataSource _localDataSource;

  HomeRepository(this._api, this._localDataSource);

  @override
  TaskEither<AppException, SkillsetEntity> getSkillset(String id) {
    return callApiWithTransform<SkillsetModel, SkillsetEntity>(
      apiCall: () => _api.getSkillset(id),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheSkillset(data ?? SkillsetModel()),
      onError: () async {
        final cachedModel = await _localDataSource.getCachedSkillset(id);
        return cachedModel?.toEntity();
      },
      defaultValue: SkillsetEntity(),
    );
  }

  @override
  TaskEither<AppException, BasePageBreak<SkillsetEntity>> getAllSkillsets(
    PageBreakRequest request,
  ) {
    return callApiPageBreak<SkillsetModel, SkillsetEntity>(
      apiCall: () => _api.getAllSkillsets(request),
      transform: (model) => model.toEntity(),
      onSuccess: (pageData) async {
        // Cache only the items from the current page
        await _localDataSource.cacheSkillsets(pageData.items);
      },
      onError: () async {
        final cachedModels = await _localDataSource.getCachedSkillsets();
        if (cachedModels.isNotEmpty) {
          return BasePageBreak<SkillsetEntity>(
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
  TaskEither<AppException, SkillsetEntity> createSkillset(
    SkillsetEntity entity,
  ) {
    return callApiWithTransform<SkillsetModel, SkillsetEntity>(
      apiCall: () => _api.createSkillset(_entityToJson(entity)),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheSkillset(data ?? SkillsetModel()),
      defaultValue: SkillsetEntity(),
    );
  }

  @override
  TaskEither<AppException, SkillsetEntity> updateSkillset(
    SkillsetEntity entity,
  ) {
    return callApiWithTransform<SkillsetModel, SkillsetEntity>(
      apiCall: () => _api.updateSkillset(entity.id, _entityToJson(entity)),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheSkillset(data ?? SkillsetModel()),
      defaultValue: SkillsetEntity(),
    );
  }

  @override
  TaskEither<AppException, Unit> deleteSkillset(String id) {
    return executeApiAction(
      apiCall: () => _api.deleteSkillset(id),
      onSuccess: () async => await _localDataSource.deleteCachedSkillset(id),
    );
  }

  // ==================== HELPER METHODS ====================

  /// Converts SkillsetEntity to JSON Map for API requests
  /// Provides flexibility to customize the request body structure without affecting domain models
  /// Reusable helper to avoid duplication in create/update methods
  Map<String, dynamic> _entityToJson(SkillsetEntity entity) {
    return {
      'id': entity.id,
      'name': entity.name,
      // TODO: Add more fields as needed
    };
  }
}
