part of '../../roleplay.dart';

@LazySingleton(as: IRoleplayRepository)
class RoleplayRepository with RestfulRequestHandlerMixin implements IRoleplayRepository {
  final RoleplayApi _api;
  final RoleplayLocalDataSource _localDataSource;

  RoleplayRepository(this._api, this._localDataSource);

  @override
  TaskEither<AppException, SectionEntity> getSection(String id) {
    return callApiWithTransform<SectionModel, SectionEntity>(
      apiCall: () => _api.getSection(id),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheSection(data ?? SectionModel()),
      onError: () async {
        final cachedModel = await _localDataSource.getCachedSection(id);
        return cachedModel?.toEntity();
      },
      defaultValue: SectionEntity(),
    );
  }

  @override
  TaskEither<AppException, BasePageBreak<SectionEntity>> getAllSections(
    PageBreakRequest request,
  ) {
    return callApiPageBreak<SectionModel, SectionEntity>(
      apiCall: () => _api.getAllSections(request),
      transform: (model) => model.toEntity(),
      onSuccess: (pageData) async {
        // Cache only the items from the current page
        await _localDataSource.cacheSections(pageData.items);
      },
      onError: () async {
        final cachedModels = await _localDataSource.getCachedSections();
        if (cachedModels.isNotEmpty) {
          return BasePageBreak<SectionEntity>(
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
  TaskEither<AppException, SectionEntity> createSection(
    SectionEntity entity,
  ) {
    return callApiWithTransform<SectionModel, SectionEntity>(
      apiCall: () => _api.createSection(_entityToJson(entity)),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheSection(data ?? SectionModel()),
      defaultValue: SectionEntity(),
    );
  }

  @override
  TaskEither<AppException, SectionEntity> updateSection(
    SectionEntity entity,
  ) {
    return callApiWithTransform<SectionModel, SectionEntity>(
      apiCall: () => _api.updateSection(entity.id.toString(), _entityToJson(entity)),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheSection(data ?? SectionModel()),
      defaultValue: SectionEntity(),
    );
  }

  @override
  TaskEither<AppException, Unit> deleteSection(String id) {
    return executeApiAction(
      apiCall: () => _api.deleteSection(id),
      onSuccess: () async => await _localDataSource.deleteCachedSection(id),
    );
  }

  // ==================== HELPER METHODS ====================

  /// Converts SectionEntity to JSON Map for API requests
  /// Provides flexibility to customize the request body structure without affecting domain models
  /// Reusable helper to avoid duplication in create/update methods
  Map<String, dynamic> _entityToJson(SectionEntity entity) {
    return {
      'id': entity.id,
      'title': entity.title,
      'transition': entity.transition,
      'transitionColor': entity.transitionColor,
      'image': entity.image,
      'contents': entity.contents
          .map(
            (content) => {
              'id': content.id,
              'type': content.type.name,
              'conversation': {
                'name': content.conversation.name,
                'avartar': content.conversation.avartar,
                'position': content.conversation.position.name,
                'bubbleColor': content.conversation.bubbleColor,
                'textColor': content.conversation.textColor,
                'content': content.conversation.content,
                'audio': content.conversation.audio,
              },
              'leadingText': {
                'frameColor': content.leadingText.frameColor,
                'textColor': content.leadingText.textColor,
                'content': content.leadingText.content,
              },
              'hint': {
                'icon': content.hint.icon,
                'textColor': content.hint.textColor,
                'content': content.hint.content,
              },
              'exercise': content.exercise.toJson(),
            },
          )
          .toList(),
    };
  }
}
