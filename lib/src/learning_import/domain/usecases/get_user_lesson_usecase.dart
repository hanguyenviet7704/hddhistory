part of '../../learning_import.dart';

@lazySingleton
class GetUserLessonUseCase implements BaseUseCase<String, UserLessonEntity> {
  final ILearningImportRepository _repository;

  GetUserLessonUseCase(this._repository);

  @override
  TaskEither<AppException, UserLessonEntity> call(String id) =>
      _repository.getUserLesson(id);
}
