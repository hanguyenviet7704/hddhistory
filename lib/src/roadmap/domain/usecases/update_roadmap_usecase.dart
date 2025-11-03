part of '../../roadmap.dart';

@lazySingleton
class UpdateRoadmapUseCase implements UseCaseWithParams<RoadmapEntity, RoadmapEntity> {
  final IRoadmapRepository _repository;

  UpdateRoadmapUseCase(this._repository);

  @override
  TaskEither<AppException, RoadmapEntity> call(RoadmapEntity params) {
    return _repository.updateRoadmap(params);
  }
}
