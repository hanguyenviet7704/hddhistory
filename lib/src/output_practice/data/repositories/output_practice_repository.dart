part of '../../output_practice.dart';

@LazySingleton(as: IOutputPracticeRepository)
class OutputPracticeRepository with RestfulRequestHandlerMixin implements IOutputPracticeRepository {
  final OutputPracticeApi _api;
  final OutputPracticeLocalDataSource _localDataSource;

  OutputPracticeRepository(this._api, this._localDataSource);

  @override
  TaskEither<AppException, BasePageBreak<OutputPracticeMessageEntity>> getAllOutputPracticeMessages(
    OutputPracticeMessagesRequestEntity request,
  ) {
    return callApiPageBreak<OutputPracticeMessageModel, OutputPracticeMessageEntity>(
      apiCall: () => _api.getAllOutputPracticeMessages(request),
      transform: (model) => model.toEntity(),
      onSuccess: (pageData) async {
        final cachedMessages = await _localDataSource.getCachedMessages(request.conversationId);
        final mergedMessages = <String, OutputPracticeMessageModel>{
          for (final message in cachedMessages) '${message.seq}_${message.role.name}': message,
          for (final message in pageData.items) '${message.seq}_${message.role.name}': OutputPracticeMessageModel.fromJson(message.toJson()),
        }.values.toList()..sort((left, right) => left.seq.compareTo(right.seq));
        await _localDataSource.cacheMessages(request.conversationId, mergedMessages);
      },
      onError: () async {
        if (request.page > 1) return null;
        final cachedModels = await _localDataSource.getCachedMessages(request.conversationId);
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
      onSuccess: (data) async {
        final conversation = data;
        if (conversation == null) return;
        await _localDataSource.cacheConversation(sectionId, conversation);
      },
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
    final sectionId = body['sectionId']?.toString() ?? '';
    return callApiWithTransform<OutputPracticeConversationModel, OutputPracticeConversationEntity>(
      apiCall: () => _api.createOutputPracticeConversation(body),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async {
        final conversation = data;
        if (conversation == null || sectionId.isEmpty) return;
        await _localDataSource.cacheConversation(sectionId, conversation);
      },
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
