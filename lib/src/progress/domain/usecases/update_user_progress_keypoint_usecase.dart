part of '../../progress.dart';

@lazySingleton
class UpdateUserProgressKeypointUseCase implements UseCaseWithParams<String, UserProgressEntity> {
  final IProgressRepository _repository;

  UpdateUserProgressKeypointUseCase(this._repository);

  @override
  TaskEither<AppException, UserProgressEntity> call(String params) {
    return _repository.updateUserProgressKeypoint(params);
  }
}
