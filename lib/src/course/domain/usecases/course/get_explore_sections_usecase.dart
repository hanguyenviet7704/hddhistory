part of '../../../course.dart';

@lazySingleton
class GetExploreSectionsUseCase implements BaseUseCase<Unit, List<ExploreSectionEntity>> {
  final ICourseRepository _repository;

  GetExploreSectionsUseCase(this._repository);

  @override
  TaskEither<AppException, List<ExploreSectionEntity>> call(Unit params) {
    return _repository.getExploreSections();
  }
}
