part of '../../knowledge_graph.dart';

@lazySingleton
class GetKgRelatedEntitiesUseCase {
  final IKnowledgeGraphRepository _repository;

  GetKgRelatedEntitiesUseCase(this._repository);

  TaskEither<AppException, List<KgRelatedEntity>> call({
    required String id,
    int maxHops = 2,
    int limit = 20,
  }) => _repository.getRelatedEntities(id: id, maxHops: maxHops, limit: limit);
}
