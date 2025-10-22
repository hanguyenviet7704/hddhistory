part of '../../exercise.dart';

@lazySingleton
class DeleteExerciseUseCase implements UseCaseWithParams<String, Unit> {
  final IExerciseRepository _repository;

  DeleteExerciseUseCase(this._repository);

  @override
  TaskEither<AppException, Unit> call(String params) {
    return _repository.deleteExercise(params);
  }
}
