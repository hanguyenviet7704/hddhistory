part of '../../onboard.dart';

@lazySingleton
class UpdateOnboardUseCase implements UseCaseWithParams<OnboardEntity, OnboardEntity> {
  final IOnboardRepository _repository;

  UpdateOnboardUseCase(this._repository);

  @override
  TaskEither<AppException, OnboardEntity> call(OnboardEntity params) {
    return _repository.updateOnboard(params);
  }
}
