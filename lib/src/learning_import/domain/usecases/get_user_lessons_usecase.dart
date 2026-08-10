part of '../../learning_import.dart';

@lazySingleton
class GetUserLessonsUseCase {
  final ILearningImportRepository _repository;

  GetUserLessonsUseCase(this._repository);

  TaskEither<AppException, BasePageBreak<UserLessonEntity>> call({
    required int page,
    required int take,
  }) => _repository.getUserLessons(page: page, take: take);
}
