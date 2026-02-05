part of '../../progress.dart';

@lazySingleton
class GetUserProgressKeypointUseCase implements UseCaseWithParams<UserProgressFilter, KeypointResultEntity> {
  final IProgressRepository _repository;

  GetUserProgressKeypointUseCase(this._repository);

  @override
  TaskEither<AppException, KeypointResultEntity> call(UserProgressFilter params) {
    return _repository.getUserProgressKeypoint(params);
  }
}
