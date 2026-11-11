part of '../../data_collect.dart';

@lazySingleton
class UpdateUserCollectDataUseCase implements BaseUseCase<UserCollectDataEntity, UserCollectDataEntity> {
  final IDataCollectRepository _repository;

  UpdateUserCollectDataUseCase(this._repository);

  @override
  TaskEither<AppException, UserCollectDataEntity> call(UserCollectDataEntity params) {
    return _repository.updateUserCollectData(params);
  }
}
