part of '../../roleplay.dart';

@lazySingleton
class UpdateSectionUseCase implements UseCaseWithParams<SectionEntity, SectionEntity> {
  final IRoleplayRepository _repository;

  UpdateSectionUseCase(this._repository);

  @override
  TaskEither<AppException, SectionEntity> call(SectionEntity params) {
    return _repository.updateSection(params);
  }
}
