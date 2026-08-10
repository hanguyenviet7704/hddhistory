part of '../../learning_import.dart';

@lazySingleton
class GetImportQuotaUseCase implements BaseUseCase<Unit, ImportQuotaEntity> {
  final ILearningImportRepository _repository;

  GetImportQuotaUseCase(this._repository);

  @override
  TaskEither<AppException, ImportQuotaEntity> call(Unit _) =>
      _repository.getQuota();
}
