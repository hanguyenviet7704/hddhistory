part of '../../roadmap.dart';

@lazySingleton
class GetAllRoadmapsUseCase implements UseCaseWithParams<PageBreakRequest, BasePageBreak<RoadmapEntity>> {
  final IRoadmapRepository _repository;

  GetAllRoadmapsUseCase(this._repository);

  @override
  TaskEither<AppException, BasePageBreak<RoadmapEntity>> call(PageBreakRequest params) {
    return _repository.getAllRoadmaps(params);
  }
}
