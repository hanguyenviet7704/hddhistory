part of '../../data_collect.dart';

@lazySingleton
class CreateUserCollectDataUseCase implements BaseUseCase<UserCollectDataEntity, UserCollectDataEntity> {
  final IDataCollectRepository _repository;

  CreateUserCollectDataUseCase(this._repository);

  @override
  TaskEither<AppException, UserCollectDataEntity> call(UserCollectDataEntity params) {
    return _repository.createUserCollectData(params);
  }
}
