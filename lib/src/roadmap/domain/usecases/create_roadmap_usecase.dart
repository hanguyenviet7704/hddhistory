part of '../../roadmap.dart';

@lazySingleton
class CreateRoadmapUseCase implements UseCaseWithParams<RoadmapEntity, RoadmapEntity> {
  final IRoadmapRepository _repository;

  CreateRoadmapUseCase(this._repository);

  @override
  TaskEither<AppException, RoadmapEntity> call(RoadmapEntity params) {
    return _repository.createRoadmap(params);
  }
}
