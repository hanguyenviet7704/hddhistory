part of '../../exercise.dart';

@lazySingleton
class UpdateLearningItemUseCase implements UseCaseWithParams<LearningItemEntity, LearningItemEntity> {
  final IExerciseRepository _repository;

  UpdateLearningItemUseCase(this._repository);

  @override
  TaskEither<AppException, LearningItemEntity> call(LearningItemEntity params) {
    return _repository.updateLearningItem(params);
  }
}
