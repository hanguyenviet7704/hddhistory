part of '../../profile.dart';

@lazySingleton
class GetUserUseCase implements UseCaseWithParams<String, UserEntity> {
  final IProfileRepository _repository;

  GetUserUseCase(this._repository);

  @override
  TaskEither<AppException, UserEntity> call(String params) {
    return _repository.getUser(params);
  }
}
