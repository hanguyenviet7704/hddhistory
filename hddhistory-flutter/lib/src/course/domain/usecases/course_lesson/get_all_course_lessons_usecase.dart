part of '../../../course.dart';

@lazySingleton
class GetAllCourseLessonsUseCase implements BaseUseCase<PageBreakRequest, BasePageBreak<LessonEntity>> {
  final ICourseLessonRepository _repository;

  GetAllCourseLessonsUseCase(this._repository);

  @override
  TaskEither<AppException, BasePageBreak<LessonEntity>> call(PageBreakRequest params) {
    return _repository.getAllCourseLessons(params);
  }
}
