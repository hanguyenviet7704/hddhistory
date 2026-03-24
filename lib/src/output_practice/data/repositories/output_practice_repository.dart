part of '../../output_practice.dart';

@LazySingleton(as: IOutputPracticeRepository)
class OutputPracticeRepository with RestfulRequestHandlerMixin implements IOutputPracticeRepository {
  final OutputPracticeApi _api;
  final OutputPracticeLocalDataSource _localDataSource;
  

  OutputPracticeRepository(
    this._api,
    this._localDataSource,
  );

  @override
  TaskEither<AppException, OutputPracticeConversationEntity> getOutputPracticeConversation(String id) {
    return callApiWithTransform<OutputPracticeConversationModel, OutputPracticeConversationEntity>(
      apiCall: () => _api.getOutputPracticeConversation(id),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheOutputPracticeConversation(data ?? OutputPracticeConversationModel()),
      onError: () async {
        final cachedModel = await _localDataSource.getCachedOutputPracticeConversation(id);
        return cachedModel?.toEntity();
      },
      defaultValue: OutputPracticeConversationEntity(),
    );
  }

  @override
  TaskEither<AppException, BasePageBreak<OutputPracticeConversationEntity>> getAllOutputPracticeConversations(
    PageBreakRequest request,
  ) {
    return callApiPageBreak<OutputPracticeConversationModel, OutputPracticeConversationEntity>(
      apiCall: () => _api.getAllOutputPracticeConversations(request),
      transform: (model) => model.toEntity(),
      onSuccess: (pageData) async => await _localDataSource.cacheOutputPracticeConversations(pageData.items),
      onError: () async {
        final cachedModels = await _localDataSource.getCachedOutputPracticeConversations();
        if (cachedModels.isNotEmpty) {
          return BasePageBreak<OutputPracticeConversationEntity>(
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
  TaskEither<AppException, OutputPracticeConversationEntity> createOutputPracticeConversation(
    OutputPracticeConversationEntity entity,
  ) {
    return callApiWithTransform<OutputPracticeConversationModel, OutputPracticeConversationEntity>(
      apiCall: () => _api.createOutputPracticeConversation(_entityToJson(entity)),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheOutputPracticeConversation(data ?? OutputPracticeConversationModel()),
      defaultValue: OutputPracticeConversationEntity(),
    );
  }

  @override
  TaskEither<AppException, OutputPracticeConversationEntity> updateOutputPracticeConversation(
    OutputPracticeConversationEntity entity,
  ) {
    return callApiWithTransform<OutputPracticeConversationModel, OutputPracticeConversationEntity>(
      apiCall: () => _api.updateOutputPracticeConversation(entity.id, _entityToJson(entity)),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheOutputPracticeConversation(data ?? OutputPracticeConversationModel()),
      defaultValue: OutputPracticeConversationEntity(),
    );
  }

  @override
  TaskEither<AppException, Unit> deleteOutputPracticeConversation(String id) {
    return executeApiAction(
      apiCall: () => _api.deleteOutputPracticeConversation(id),
      onSuccess: () async => await _localDataSource.deleteCachedOutputPracticeConversation(id),
    );
  }
  

  // ==================== HELPER METHODS ====================

  /// Converts OutputPracticeConversationEntity to JSON Map for API requests
  /// Provides flexibility to customize the request body structure without affecting domain models
  /// Reusable helper to avoid duplication in create/update methods
  Map<String, dynamic> _entityToJson(OutputPracticeConversationEntity entity) {
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

