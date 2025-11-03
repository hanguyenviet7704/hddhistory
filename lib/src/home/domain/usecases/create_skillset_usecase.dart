part of '../../home.dart';

@lazySingleton
class CreateSkillsetUseCase implements UseCaseWithParams<SkillsetEntity, SkillsetEntity> {
  final IHomeRepository _repository;

  CreateSkillsetUseCase(this._repository);

  @override
  TaskEither<AppException, SkillsetEntity> call(SkillsetEntity params) {
    return _repository.createSkillset(params);
  }
}
