part of '../../onboard_v2.dart';

@lazySingleton
class GetAllOnboardV2sUseCase implements BaseUseCase<PageBreakRequest, BasePageBreak<OnboardV2Entity>> {
  final IOnboardV2Repository _repository;

  GetAllOnboardV2sUseCase(this._repository);

  @override
  TaskEither<AppException, BasePageBreak<OnboardV2Entity>> call(PageBreakRequest params) {
    return _repository.getAllOnboardV2s(params);
  }
}
