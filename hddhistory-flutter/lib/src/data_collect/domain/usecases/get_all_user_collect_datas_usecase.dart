part of '../../data_collect.dart';

@lazySingleton
class GetAllUserCollectDatasUseCase implements BaseUseCase<Unit, List<UserCollectDataEntity>> {
  final IDataCollectRepository _repository;

  GetAllUserCollectDatasUseCase(this._repository);

  @override
  TaskEither<AppException, List<UserCollectDataEntity>> call(Unit _) {
    return _repository.getAllUserCollectDatas();
  }
}
