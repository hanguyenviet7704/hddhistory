part of '../../home.dart';

@lazySingleton
class GetHomeBannerUseCase {
  final IHomeRepository _repository;

  GetHomeBannerUseCase(this._repository);

  TaskEither<AppException, HomeBannerEntity> call() => _repository.getHomeBanner();
}
