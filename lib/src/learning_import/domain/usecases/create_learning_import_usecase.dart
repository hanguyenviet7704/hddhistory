part of '../../learning_import.dart';

@lazySingleton
class CreateLearningImportUseCase
    implements BaseUseCase<CreateLearningImportParams, LearningImportJobEntity> {
  final ILearningImportRepository _repository;

  CreateLearningImportUseCase(this._repository);

  @override
  TaskEither<AppException, LearningImportJobEntity> call(
    CreateLearningImportParams params,
  ) => _repository.createImport(params);
}
