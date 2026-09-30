part of '../../knowledge_graph.dart';

abstract class IKnowledgeGraphRepository {
  TaskEither<AppException, List<KgEntitySummary>> searchEntities({
    required String query,
    int limit,
  });

  TaskEither<AppException, KgEntityProfile> getEntityProfile(String id);

  TaskEither<AppException, List<KgRelatedEntity>> getRelatedEntities({
    required String id,
    int maxHops,
    int limit,
  });
}
