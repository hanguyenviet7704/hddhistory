part of '../../learning_import.dart';

@lazySingleton
class GetLearningImportJobUseCase
    implements BaseUseCase<String, LearningImportJobEntity> {
  final ILearningImportRepository _repository;

  GetLearningImportJobUseCase(this._repository);

  @override
  TaskEither<AppException, LearningImportJobEntity> call(String jobId) =>
      _repository.getJob(jobId);
}
