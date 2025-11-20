part of '../../profile.dart';

@lazySingleton
class UpdateUserUseCase implements UseCaseWithParams<Map<String, dynamic>, UserEntity> {
  final IProfileRepository _repository;

  UpdateUserUseCase(this._repository);

  @override
  TaskEither<AppException, UserEntity> call(Map<String, dynamic> params) {
    return _repository.updateUser(params);
  }
}
