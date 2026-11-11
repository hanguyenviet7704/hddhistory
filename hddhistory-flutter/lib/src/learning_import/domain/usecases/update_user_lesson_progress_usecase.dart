part of '../../learning_import.dart';

@lazySingleton
class UpdateUserLessonProgressUseCase
    implements BaseUseCase<UpdateLessonProgressParams, Unit> {
  final ILearningImportRepository _repository;

  UpdateUserLessonProgressUseCase(this._repository);

  @override
  TaskEither<AppException, Unit> call(UpdateLessonProgressParams params) =>
      _repository.updateProgress(params);
}
