part of '../../knowledge_graph.dart';

@lazySingleton
class GetKgEntityProfileUseCase
    implements BaseUseCase<String, KgEntityProfile> {
  final IKnowledgeGraphRepository _repository;

  GetKgEntityProfileUseCase(this._repository);

  @override
  TaskEither<AppException, KgEntityProfile> call(String id) =>
      _repository.getEntityProfile(id);
}
