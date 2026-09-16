part of '../../../course.dart';

@lazySingleton
class GetExploreSectionsUseCase implements BaseUseCase<int, List<ExploreSectionEntity>> {
  final ICourseRepository _repository;

  GetExploreSectionsUseCase(this._repository);

  /// [params] is this session's shuffle seed — see
  /// `ExploreCubit.ensureExploreDataLoaded`.
  @override
  TaskEither<AppException, List<ExploreSectionEntity>> call(int params) {
    return _repository.getExploreSections(params);
  }
}
