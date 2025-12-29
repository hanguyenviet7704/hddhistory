part of '../../progress.dart';

@lazySingleton
class GetAllAchievenmentResponsesUseCase implements UseCaseWithoutParams<List<AchievenmentResponseEntity>> {
  final IAchievenmentProgressRepository _repository;

  GetAllAchievenmentResponsesUseCase(this._repository);

  @override
  TaskEither<AppException, List<AchievenmentResponseEntity>> call() {
    return _repository.getAllAchievenmentResponses();
  }
}
