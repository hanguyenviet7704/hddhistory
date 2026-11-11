part of '../../../course.dart';

@lazySingleton
class ClearSearchHistoryUseCase implements BaseUseCase<Unit, Unit> {
  final ICourseRepository _repository;

  ClearSearchHistoryUseCase(this._repository);

  @override
  TaskEither<AppException, Unit> call(Unit params) {
    return _repository.clearSearchHistory();
  }
}
