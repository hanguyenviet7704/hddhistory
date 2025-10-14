part of '../../onboard.dart';

@lazySingleton
class GetOnboardUseCase implements UseCaseWithParams<String, OnboardEntity> {
  final IOnboardRepository _repository;

  GetOnboardUseCase(this._repository);

  @override
  TaskEither<AppException, OnboardEntity> call(String params) {
    return _repository.getOnboard(params);
  }
}
