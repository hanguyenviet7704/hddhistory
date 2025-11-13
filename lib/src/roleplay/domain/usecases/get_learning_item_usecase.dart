part of '../../roleplay.dart';

@lazySingleton
class GetRoleplayLearningItemUseCase implements UseCaseWithParams<String, LearningItemEntity> {
  final IRoleplayRepository _repository;

  GetRoleplayLearningItemUseCase(this._repository);

  @override
  TaskEither<AppException, LearningItemEntity> call(String params) {
    return _repository.getLearningItem(params);
  }
}
