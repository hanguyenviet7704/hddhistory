part of '../../learning_import.dart';

@lazySingleton
class DeleteUserLessonUseCase implements BaseUseCase<String, Unit> {
  final ILearningImportRepository _repository;

  DeleteUserLessonUseCase(this._repository);

  @override
  TaskEither<AppException, Unit> call(String id) =>
      _repository.deleteUserLesson(id);
}
