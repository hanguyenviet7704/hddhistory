part of '../../roleplay.dart';

@lazySingleton
class DeleteSectionUseCase implements UseCaseWithParams<String, Unit> {
  final IRoleplayRepository _repository;

  DeleteSectionUseCase(this._repository);

  @override
  TaskEither<AppException, Unit> call(String params) {
    return _repository.deleteSection(params);
  }
}
