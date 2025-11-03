part of '../../roadmap.dart';

@lazySingleton
class GetRoadmapUseCase implements UseCaseWithParams<String, RoadmapEntity> {
  final IRoadmapRepository _repository;

  GetRoadmapUseCase(this._repository);

  @override
  TaskEither<AppException, RoadmapEntity> call(String params) {
    return _repository.getRoadmap(params);
  }
}
