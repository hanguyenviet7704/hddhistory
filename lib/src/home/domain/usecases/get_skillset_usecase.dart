part of '../../home.dart';

@lazySingleton
class GetSkillsetUseCase implements UseCaseWithParams<String, SkillsetEntity> {
  final IHomeRepository _repository;

  GetSkillsetUseCase(this._repository);

  @override
  TaskEither<AppException, SkillsetEntity> call(String params) {
    return _repository.getSkillset(params);
  }
}
