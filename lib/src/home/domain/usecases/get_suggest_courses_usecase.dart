part of '../../home.dart';

@lazySingleton
class GetSuggestCoursesUseCase {
  final IHomeRepository _repository;

  GetSuggestCoursesUseCase(this._repository);

  TaskEither<AppException, List<SuggestedCourseEntity>> call(int limit) => _repository.getSuggestCourses(limit);
}
