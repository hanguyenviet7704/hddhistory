part of '../../exercise.dart';

@lazySingleton
class UpdateExerciseUseCase implements UseCaseWithParams<ExerciseEntity, ExerciseEntity> {
  final IExerciseRepository _repository;

  UpdateExerciseUseCase(this._repository);

  @override
  TaskEither<AppException, ExerciseEntity> call(ExerciseEntity params) {
    return _repository.updateExercise(params);
  }
}
