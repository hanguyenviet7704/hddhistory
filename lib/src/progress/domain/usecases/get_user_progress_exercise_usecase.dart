part of '../../progress.dart';

@lazySingleton
class GetUserProgressExerciseUseCase implements UseCaseWithParams<String, UserProgressEntity> {
  final IProgressRepository _repository;

  GetUserProgressExerciseUseCase(this._repository);

  @override
  TaskEither<AppException, UserProgressEntity> call(String params) {
    return _repository.getUserProgressExercise(params);
  }
}

