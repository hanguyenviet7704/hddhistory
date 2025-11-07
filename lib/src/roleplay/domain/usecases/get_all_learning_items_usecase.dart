part of '../../roleplay.dart';

@lazySingleton
class GetAllRoleplayLearningItemsUseCase implements UseCaseWithParams<PageBreakRequest, BasePageBreak<LearningItemEntity>> {
  final IRoleplayRepository _repository;

  GetAllRoleplayLearningItemsUseCase(this._repository);

  @override
  TaskEither<AppException, BasePageBreak<LearningItemEntity>> call(PageBreakRequest params) {
    return _repository.getAllLearningItems(params);
  }
}
