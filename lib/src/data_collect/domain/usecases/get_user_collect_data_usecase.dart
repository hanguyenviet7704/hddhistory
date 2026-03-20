part of '../../data_collect.dart';

@lazySingleton
class GetUserCollectDataUseCase implements BaseUseCase<String, UserCollectDataEntity> {
  final IDataCollectRepository _repository;

  GetUserCollectDataUseCase(this._repository);

  @override
  TaskEither<AppException, UserCollectDataEntity> call(String params) {
    return _repository.getUserCollectData(params);
  }
}
