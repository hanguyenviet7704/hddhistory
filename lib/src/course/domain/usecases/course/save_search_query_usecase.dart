part of '../../../course.dart';

@lazySingleton
class SaveSearchQueryUseCase implements BaseUseCase<String, Unit> {
  final ICourseRepository _repository;

  SaveSearchQueryUseCase(this._repository);

  @override
  TaskEither<AppException, Unit> call(String query) {
    return _repository.saveSearchQuery(query);
  }
}
