part of '../../profile.dart';

@lazySingleton
class DeleteUserUseCase implements UseCaseWithParams<String, Unit> {
  final IProfileRepository _repository;

  DeleteUserUseCase(this._repository);

  @override
  TaskEither<AppException, Unit> call(String params) {
    return _repository.deleteUser(params);
  }
}
