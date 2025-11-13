part of '../../progress.dart';

@lazySingleton
class GetAllUserProgresssUseCase implements UseCaseWithParams<PageBreakRequest, BasePageBreak<UserProgressEntity>> {
  final IProgressRepository _repository;

  GetAllUserProgresssUseCase(this._repository);

  @override
  TaskEither<AppException, BasePageBreak<UserProgressEntity>> call(PageBreakRequest params) {
    return _repository.getAllUserProgresss(params);
  }
}
