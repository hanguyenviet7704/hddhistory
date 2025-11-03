part of '../../roadmap.dart';

@lazySingleton
class DeleteRoadmapUseCase implements UseCaseWithParams<String, Unit> {
  final IRoadmapRepository _repository;

  DeleteRoadmapUseCase(this._repository);

  @override
  TaskEither<AppException, Unit> call(String params) {
    return _repository.deleteRoadmap(params);
  }
}
