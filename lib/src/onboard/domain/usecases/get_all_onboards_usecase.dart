part of '../../onboard.dart';

@lazySingleton
class GetAllOnboardsUseCase implements UseCaseWithoutParams<List<OnboardEntity>> {
  final IOnboardRepository _repository;

  GetAllOnboardsUseCase(this._repository);

  @override
  TaskEither<AppException, List<OnboardEntity>> call() {
    return _repository.getAllOnboards();
  }
}
