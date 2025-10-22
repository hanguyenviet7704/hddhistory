part of '../../profile.dart';

@lazySingleton
class CreateUserUseCase implements UseCaseWithParams<UserEntity, UserEntity> {
  final IProfileRepository _repository;

  CreateUserUseCase(this._repository);

  @override
  TaskEither<AppException, UserEntity> call(UserEntity params) {
    return _repository.createUser(params);
  }
}
