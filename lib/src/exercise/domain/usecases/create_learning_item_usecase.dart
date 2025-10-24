part of '../../exercise.dart';

@lazySingleton
class CreateLearningItemUseCase implements UseCaseWithParams<LearningItemEntity, LearningItemEntity> {
  final IExerciseRepository _repository;

  CreateLearningItemUseCase(this._repository);

  @override
  TaskEither<AppException, LearningItemEntity> call(LearningItemEntity params) {
    return _repository.createLearningItem(params);
  }
}
