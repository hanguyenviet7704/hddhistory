part of '../../exercise.dart';

@lazySingleton
class CreateExerciseUseCase implements UseCaseWithParams<ExerciseEntity, ExerciseEntity> {
  final IExerciseRepository _repository;

  CreateExerciseUseCase(this._repository);

  @override
  TaskEither<AppException, ExerciseEntity> call(ExerciseEntity params) {
    return _repository.createExercise(params);
  }
}
