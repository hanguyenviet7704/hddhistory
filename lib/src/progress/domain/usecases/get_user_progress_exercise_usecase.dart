part of '../../progress.dart';

@lazySingleton
class GetUserProgressExerciseUseCase implements UseCaseWithParams<UserProgressFilter, ExerciseResultEntity> {
  final IProgressRepository _repository;

  GetUserProgressExerciseUseCase(this._repository);

  @override
  TaskEither<AppException, ExerciseResultEntity> call(UserProgressFilter params) {
    return _repository.getUserProgressExercise(params);
  }
}
