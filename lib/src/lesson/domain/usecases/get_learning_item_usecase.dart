part of '../../lesson.dart';

@lazySingleton
class GetLearningItemUseCase implements UseCaseWithParams<String, LearningItemEntity> {
  final ILessonRepository _repository;

  GetLearningItemUseCase(this._repository);

  @override
  TaskEither<AppException, LearningItemEntity> call(String params) {
    return _repository.getLearningItem(params);
  }
}
