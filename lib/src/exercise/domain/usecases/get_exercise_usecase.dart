part of '../../exercise.dart';

@lazySingleton
class GetExerciseUseCase implements UseCaseWithParams<String, ExerciseEntity> {
  final IExerciseRepository _repository;

  GetExerciseUseCase(this._repository);

  @override
  TaskEither<AppException, ExerciseEntity> call(String params) {
    return _repository.getExercise(params);
  }
}
