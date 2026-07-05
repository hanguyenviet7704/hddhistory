part of '../../warm_up.dart';

@lazySingleton
class CheckWarmUpForCourseUseCase implements BaseUseCase<String, WarmUpForCourseEntity> {
  final IWarmUpRepository _repository;

  CheckWarmUpForCourseUseCase(this._repository);

  @override
  TaskEither<AppException, WarmUpForCourseEntity> call(String courseId) {
    return _repository.getWarmUpForCourse(courseId);
  }
}
