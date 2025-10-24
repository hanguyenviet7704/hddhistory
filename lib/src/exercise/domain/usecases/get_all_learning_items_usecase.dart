part of '../../exercise.dart';

@lazySingleton
class GetAllLearningItemsUseCase implements UseCaseWithParams<PageBreakRequest, BasePageBreak<LearningItemEntity>> {
  final IExerciseRepository _repository;

  GetAllLearningItemsUseCase(this._repository);

  @override
  TaskEither<AppException, BasePageBreak<LearningItemEntity>> call(PageBreakRequest params) {
    return _repository.getAllLearningItems(params);
  }
}
