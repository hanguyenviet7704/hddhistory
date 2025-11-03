part of '../../home.dart';

@lazySingleton
class UpdateSkillsetUseCase implements UseCaseWithParams<SkillsetEntity, SkillsetEntity> {
  final IHomeRepository _repository;

  UpdateSkillsetUseCase(this._repository);

  @override
  TaskEither<AppException, SkillsetEntity> call(SkillsetEntity params) {
    return _repository.updateSkillset(params);
  }
}
