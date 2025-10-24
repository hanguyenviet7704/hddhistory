part of '../../exercise.dart';

@lazySingleton
class GetLearningItemUseCase implements UseCaseWithParams<String, LearningItemEntity> {
  final IExerciseRepository _repository;

  GetLearningItemUseCase(this._repository);

  @override
  TaskEither<AppException, LearningItemEntity> call(String params) {
    return _repository.getLearningItem(params);
  }
}
