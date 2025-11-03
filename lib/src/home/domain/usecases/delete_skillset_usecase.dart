part of '../../home.dart';

@lazySingleton
class DeleteSkillsetUseCase implements UseCaseWithParams<String, Unit> {
  final IHomeRepository _repository;

  DeleteSkillsetUseCase(this._repository);

  @override
  TaskEither<AppException, Unit> call(String params) {
    return _repository.deleteSkillset(params);
  }
}
