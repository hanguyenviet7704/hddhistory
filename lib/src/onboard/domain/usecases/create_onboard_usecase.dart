part of '../../onboard.dart';

@lazySingleton
class CreateOnboardUseCase implements UseCaseWithParams<OnboardEntity, OnboardEntity> {
  final IOnboardRepository _repository;

  CreateOnboardUseCase(this._repository);

  @override
  TaskEither<AppException, OnboardEntity> call(OnboardEntity params) {
    return _repository.createOnboard(params);
  }
}
