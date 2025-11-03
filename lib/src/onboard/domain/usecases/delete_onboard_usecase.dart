part of '../../onboard.dart';

@lazySingleton
class DeleteOnboardUseCase implements UseCaseWithParams<String, Unit> {
  final IOnboardRepository _repository;

  DeleteOnboardUseCase(this._repository);

  @override
  TaskEither<AppException, Unit> call(String params) {
    return _repository.deleteOnboard(params);
  }
}
