part of '../../exercise.dart';

@lazySingleton
class DeleteLearningItemUseCase implements UseCaseWithParams<String, Unit> {
  final IExerciseRepository _repository;

  DeleteLearningItemUseCase(this._repository);

  @override
  TaskEither<AppException, Unit> call(String params) {
    return _repository.deleteLearningItem(params);
  }
}
