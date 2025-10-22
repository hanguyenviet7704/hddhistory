part of '../../profile.dart';

@lazySingleton
class UpdateUserUseCase implements UseCaseWithParams<UserEntity, UserEntity> {
  final IProfileRepository _repository;

  UpdateUserUseCase(this._repository);

  @override
  TaskEither<AppException, UserEntity> call(UserEntity params) {
    return _repository.updateUser(params);
  }
}
