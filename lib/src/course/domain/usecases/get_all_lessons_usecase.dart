part of '../../course.dart';

@lazySingleton
class GetAllLessonsUseCase implements UseCaseWithParams<PageBreakRequest, BasePageBreak<LessonEntity>> {
  final ICourseLessonRepository _repository;

  GetAllLessonsUseCase(this._repository);

  @override
  TaskEither<AppException, BasePageBreak<LessonEntity>> call(PageBreakRequest params) {
    return _repository.getAllLessons(params);
  }
}

