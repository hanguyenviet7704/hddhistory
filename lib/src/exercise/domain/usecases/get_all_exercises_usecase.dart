part of '../../exercise.dart';

@lazySingleton
class GetAllExercisesUseCase implements UseCaseWithParams<PageBreakRequest, BasePageBreak<ExerciseEntity>> {
  final IExerciseRepository _repository;

  GetAllExercisesUseCase(this._repository);

  @override
  TaskEither<AppException, BasePageBreak<ExerciseEntity>> call(PageBreakRequest params) {
    return _repository.getAllExercises(params);
  }
}
