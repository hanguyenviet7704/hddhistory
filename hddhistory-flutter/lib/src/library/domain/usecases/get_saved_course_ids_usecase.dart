part of '../../library.dart';

@lazySingleton
class GetSavedCourseIdsUseCase {
  final ISavedRepository _repository;

  GetSavedCourseIdsUseCase(this._repository);

  TaskEither<AppException, List<String>> call() => _repository.getSavedCourseIds();
}
