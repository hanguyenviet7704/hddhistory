part of '../../onboard.dart';

@lazySingleton
class GetAllOnboardsUseCase implements BaseUseCase<Unit, OnboardEntity> {
  final IOnboardRepository _repository;

  GetAllOnboardsUseCase(this._repository);

  @override
  TaskEither<AppException, OnboardEntity> call(Unit _) {
    return _repository.getAllOnboards();
  }
}
