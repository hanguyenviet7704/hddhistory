part of '../../progress.dart';

@lazySingleton
class GetAllAchievenmentResponsesUseCase implements BaseUseCase<Unit, List<AchievenmentResponseEntity>> {
  final IAchievenmentProgressRepository _repository;

  GetAllAchievenmentResponsesUseCase(this._repository);

  @override
  TaskEither<AppException, List<AchievenmentResponseEntity>> call(Unit _) {
    return _repository.getAllAchievenmentResponses();
  }
}
