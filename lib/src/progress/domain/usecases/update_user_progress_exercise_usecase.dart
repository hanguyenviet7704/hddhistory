part of '../../progress.dart';

@lazySingleton
class UpdateUserProgressExerciseUseCase implements UseCaseWithParams<String, UserProgressEntity> {
  final IProgressRepository _repository;

  UpdateUserProgressExerciseUseCase(this._repository);

  @override
  TaskEither<AppException, UserProgressEntity> call(String params) {
    return _repository.updateUserProgressExercise(params);
  }
}
