part of '../../progress.dart';

@lazySingleton
class CreateCompletedLevelAdditionalContentRequestUseCase implements BaseUseCase<Map<String, dynamic>, UserProgressEntity> {
  final IContentRequestRepository _repository;

  CreateCompletedLevelAdditionalContentRequestUseCase(this._repository);

  @override
  TaskEither<AppException, UserProgressEntity> call(Map<String, dynamic> params) {
    return _repository.createCompletedLevelAdditionalContentRequest(params);
  }
}
