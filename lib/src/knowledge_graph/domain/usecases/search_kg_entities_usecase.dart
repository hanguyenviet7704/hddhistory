part of '../../knowledge_graph.dart';

@lazySingleton
class SearchKgEntitiesUseCase {
  final IKnowledgeGraphRepository _repository;

  SearchKgEntitiesUseCase(this._repository);

  TaskEither<AppException, List<KgEntitySummary>> call({
    required String query,
    int limit = 20,
  }) => _repository.searchEntities(query: query, limit: limit);
}
