part of '../../../course.dart';

@lazySingleton
class GetSearchHistoryUseCase implements BaseUseCase<Unit, List<String>> {
  final ICourseRepository _repository;

  GetSearchHistoryUseCase(this._repository);

  @override
  TaskEither<AppException, List<String>> call(Unit params) {
    return _repository.getSearchHistory();
  }
}
