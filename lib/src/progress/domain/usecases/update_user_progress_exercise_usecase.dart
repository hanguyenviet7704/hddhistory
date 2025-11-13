part of '../../progress.dart';

class UpdateUserProgressExerciseParams {
  final String exerciseId;
  final Map<String, dynamic> body;

  UpdateUserProgressExerciseParams({required this.exerciseId, required this.body});
}

@lazySingleton
class UpdateUserProgressExerciseUseCase implements UseCaseWithParams<UpdateUserProgressExerciseParams, UserProgressEntity> {
  final IProgressRepository _repository;

  UpdateUserProgressExerciseUseCase(this._repository);

  @override
  TaskEither<AppException, UserProgressEntity> call(UpdateUserProgressExerciseParams params) {
    return _repository.updateUserProgressExercise(params.exerciseId, params.body);
  }
}
