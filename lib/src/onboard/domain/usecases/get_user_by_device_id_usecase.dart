part of '../../onboard.dart';

@lazySingleton
class GetUserByDeviceIdUseCase implements BaseUseCase<String, UserEntity> {
  final IOnboardRepository _repository;

  GetUserByDeviceIdUseCase(this._repository);

  @override
  TaskEither<AppException, UserEntity> call(String params) {
    return _repository.getUserByDeviceId(params);
  }
}
