part of '../../onboard_v2.dart';

@lazySingleton
class GetOnboardV2UseCase implements BaseUseCase<String, OnboardV2Entity> {
  final IOnboardV2Repository _repository;

  GetOnboardV2UseCase(this._repository);

  @override
  TaskEither<AppException, OnboardV2Entity> call(String params) {
    return _repository.getOnboardV2(params);
  }
}
