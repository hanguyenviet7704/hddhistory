part of '../../../course.dart';

@lazySingleton
class GetRoadmapUseCase implements BaseUseCase<String, RoadmapEntity> {
  final ICourseRepository _repository;

  GetRoadmapUseCase(this._repository);

  @override
  TaskEither<AppException, RoadmapEntity> call(String courseId) {
    return _repository.getRoadmap(courseId);
  }
}
