part of '../../progress.dart';

@freezed
abstract class UserProgressMyCoursesUseCaseFilter with _$UserProgressMyCoursesUseCaseFilter implements JsonRequestConvertible {
  const factory UserProgressMyCoursesUseCaseFilter({
    @Default(false) bool recent,
  }) = _UserProgressMyCoursesUseCaseFilter;

  factory UserProgressMyCoursesUseCaseFilter.fromJson(Map<String, dynamic> json) => _$UserProgressMyCoursesUseCaseFilterFromJson(json);
}

@lazySingleton
class GetUserProgressMyCoursesUseCase implements UseCaseWithParams<PageBreakRequest, BasePageBreak<CourseEntity>> {
  final IProgressRepository _repository;

  GetUserProgressMyCoursesUseCase(this._repository);

  @override
  TaskEither<AppException, BasePageBreak<CourseEntity>> call(PageBreakRequest params) {
    return _repository.getUserProgressMyCourses(params);
  }
}

