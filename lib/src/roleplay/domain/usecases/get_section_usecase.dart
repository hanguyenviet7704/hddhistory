part of '../../roleplay.dart';

@lazySingleton
class GetSectionUseCase implements UseCaseWithParams<String, SectionEntity> {
  final IRoleplayRepository _repository;

  GetSectionUseCase(this._repository);

  @override
  TaskEither<AppException, SectionEntity> call(String params) {
    return _repository.getSection(params);
  }
}
