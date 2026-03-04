part of '../../progress.dart';

@lazySingleton
class GetCourseLevelProgressUseCase implements BaseUseCase<String, List<CourseLevelProgressEntity>> {
  final IAchievenmentProgressRepository _repository;

  GetCourseLevelProgressUseCase(this._repository);

  @override
  TaskEither<AppException, List<CourseLevelProgressEntity>> call(String params) {
    return _repository.getCourseLevelProgress(params);
  }
}
