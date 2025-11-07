part of '../../roleplay.dart';

@lazySingleton
class CreateSectionUseCase implements UseCaseWithParams<SectionEntity, SectionEntity> {
  final IRoleplayRepository _repository;

  CreateSectionUseCase(this._repository);

  @override
  TaskEither<AppException, SectionEntity> call(SectionEntity params) {
    return _repository.createSection(params);
  }
}
