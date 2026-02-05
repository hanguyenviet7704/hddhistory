part of '../../data_collect.dart';

@lazySingleton
class GetAllUserCollectDatasUseCase implements UseCaseWithoutParams<List<UserCollectDataEntity>> {
  final IDataCollectRepository _repository;

  GetAllUserCollectDatasUseCase(this._repository);

  @override
  TaskEither<AppException, List<UserCollectDataEntity>> call() {
    return _repository.getAllUserCollectDatas();
  }
}
