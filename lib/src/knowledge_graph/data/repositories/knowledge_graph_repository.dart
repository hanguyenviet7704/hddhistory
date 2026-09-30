part of '../../knowledge_graph.dart';

@LazySingleton(as: IKnowledgeGraphRepository)
class KnowledgeGraphRepository
    with RestfulRequestHandlerMixin
    implements IKnowledgeGraphRepository {
  final KnowledgeGraphApi _api;

  KnowledgeGraphRepository(this._api);

  @override
  TaskEither<AppException, List<KgEntitySummary>> searchEntities({
    required String query,
    int limit = 20,
  }) {
    // Im lặng (không toast): ô tìm kiếm gõ tới đâu gọi tới đó, một lần hỏng
    // mạng giữa chừng mà bắn toast thì người dùng lãnh một chuỗi toast trong
    // lúc đang gõ. Màn hình tự hiện trạng thái lỗi của nó.
    return callApiWithTransform<List<KgEntitySummaryModel>, List<KgEntitySummary>>(
      apiCall: () => _api.searchEntities(q: query, limit: limit),
      transform: (models) => models.map((m) => m.toEntity()).toList(),
      defaultValue: const [],
      enableErrorMessages: false,
    );
  }

  @override
  TaskEither<AppException, KgEntityProfile> getEntityProfile(String id) {
    return callApiWithTransform<KgEntityProfileModel, KgEntityProfile>(
      apiCall: () => _api.getEntityProfile(id),
      transform: (model) => model.toEntity(),
      defaultValue: const KgEntityProfile(
        id: '',
        type: KgEntityType.unknown,
        name: '',
      ),
      enableErrorMessages: false,
    );
  }

  @override
  TaskEither<AppException, List<KgRelatedEntity>> getRelatedEntities({
    required String id,
    int maxHops = 2,
    int limit = 20,
  }) {
    return callApiWithTransform<List<KgRelatedEntityModel>, List<KgRelatedEntity>>(
      apiCall: () => _api.getRelatedEntities(id, maxHops: maxHops, limit: limit),
      transform: (models) => models.map((m) => m.toEntity()).toList(),
      defaultValue: const [],
      enableErrorMessages: false,
    );
  }
}
