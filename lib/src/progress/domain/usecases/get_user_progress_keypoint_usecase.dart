part of '../../progress.dart';

@lazySingleton
class GetUserProgressKeypointUseCase implements UseCaseWithParams<String, UserProgressEntity> {
  final IProgressRepository _repository;

  GetUserProgressKeypointUseCase(this._repository);

  @override
  TaskEither<AppException, UserProgressEntity> call(String params) {
    return _repository.getUserProgressKeypoint(params);
  }
}

