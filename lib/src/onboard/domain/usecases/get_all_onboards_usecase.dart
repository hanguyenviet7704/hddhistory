part of '../../onboard.dart';

@lazySingleton
class GetAllOnboardsUseCase implements UseCaseWithParams<PageBreakRequest, BasePageBreak<OnboardEntity>> {
  final IOnboardRepository _repository;

  GetAllOnboardsUseCase(this._repository);

  @override
  TaskEither<AppException, BasePageBreak<OnboardEntity>> call(PageBreakRequest params) {
    return _repository.getAllOnboards(params);
  }
}
