part of '../../progress.dart';

@lazySingleton
class GetAllAchievenmentResponsesUseCase implements UseCaseWithParams<UserProgressFilter, List<AchievenmentResponseEntity>> {
  final IAchievenmentProgressRepository _repository;

  GetAllAchievenmentResponsesUseCase(this._repository);

  @override
  TaskEither<AppException, List<AchievenmentResponseEntity>> call(UserProgressFilter params) {
    return _repository.getAllAchievenmentResponses(params);
  }
}
