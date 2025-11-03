part of '../../data_collect.dart';

@lazySingleton
class DeleteUserCollectDataUseCase implements UseCaseWithParams<String, Unit> {
  final IDataCollectRepository _repository;

  DeleteUserCollectDataUseCase(this._repository);

  @override
  TaskEither<AppException, Unit> call(String params) {
    return _repository.deleteUserCollectData(params);
  }
}
