part of '../../onboard.dart';

@lazySingleton
class GetAllOnboardsUseCase implements UseCaseWithoutParams<OnboardEntity> {
  final IOnboardRepository _repository;

  GetAllOnboardsUseCase(this._repository);

  @override
  TaskEither<AppException, OnboardEntity> call() {
    return _repository.getAllOnboards();
  }
}
