part of '../../home.dart';

@lazySingleton
class GetAllSkillsetsUseCase implements UseCaseWithParams<PageBreakRequest, BasePageBreak<SkillsetEntity>> {
  final IHomeRepository _repository;

  GetAllSkillsetsUseCase(this._repository);

  @override
  TaskEither<AppException, BasePageBreak<SkillsetEntity>> call(PageBreakRequest params) {
    return _repository.getAllSkillsets(params);
  }
}
