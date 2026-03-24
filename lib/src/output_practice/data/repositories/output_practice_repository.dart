part of '../../output_practice.dart';

@LazySingleton(as: IOutputPracticeRepository)
class OutputPracticeRepository with RestfulRequestHandlerMixin implements IOutputPracticeRepository {
  final OutputPracticeApi _api;
  final OutputPracticeLocalDataSource _localDataSource;

  OutputPracticeRepository(this._api, this._localDataSource);

  @override
  TaskEither<AppException, BasePageBreak<OutputPracticeMessageEntity>> getAllOutputPracticeMessages(
    PageBreakRequest request,
  ) {
    return callApiPageBreak<OutputPracticeMessageModel, OutputPracticeMessageEntity>(
      apiCall: () => _api.getAllOutputPracticeMessages(request),
      transform: (model) => model.toEntity(),
      onSuccess: (pageData) async {
        await _localDataSource.cacheMessages(pageData.items);
      },
      onError: () async {
        final cachedModels = await _localDataSource.getCachedMessages();
        if (cachedModels.isNotEmpty) {
          return BasePageBreak<OutputPracticeMessageEntity>(
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
  TaskEither<AppException, OutputPracticeConversationEntity> getOutputPracticeConversation(String sectionId) {
    return callApiWithTransform<OutputPracticeConversationModel, OutputPracticeConversationEntity>(
      apiCall: () => _api.getOutputPracticeConversation(sectionId),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheConversation(data ?? const OutputPracticeConversationModel()),
      onError: () async {
        final cachedModel = await _localDataSource.getCachedConversation(sectionId);
        return cachedModel?.toEntity();
      },
      defaultValue: OutputPracticeConversationEntity(),
    );
  }

  @override
  TaskEither<AppException, OutputPracticeConversationEntity> createOutputPracticeConversation(
    Map<String, dynamic> body,
  ) {
    return callApiWithTransform<OutputPracticeConversationModel, OutputPracticeConversationEntity>(
      apiCall: () => _api.createOutputPracticeConversation(body),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheConversation(data ?? const OutputPracticeConversationModel()),
      defaultValue: OutputPracticeConversationEntity(),
    );
  }

  @override
  TaskEither<AppException, List<OutputPracticeMessageEntity>> sendOutputPracticeMessage(
    Map<String, dynamic> body,
  ) {
    return callApiListWithTransform<OutputPracticeMessageModel, OutputPracticeMessageEntity>(
      apiCall: () => _api.sendOutputPracticeMessage(body),
      transform: (model) => model.toEntity(),
    );
  }
}
