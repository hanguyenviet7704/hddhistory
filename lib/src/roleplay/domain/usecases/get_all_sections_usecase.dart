part of '../../roleplay.dart';

@lazySingleton
class GetAllSectionsUseCase implements UseCaseWithParams<PageBreakRequest, BasePageBreak<SectionEntity>> {
  final IRoleplayRepository _repository;

  GetAllSectionsUseCase(this._repository);

  @override
  TaskEither<AppException, BasePageBreak<SectionEntity>> call(PageBreakRequest params) {
    return _repository.getAllSections(params);
  }
}
