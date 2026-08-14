part of '../../home.dart';

@lazySingleton
class GetHomeBannerUseCase {
  final IHomeRepository _repository;

  GetHomeBannerUseCase(this._repository);

  TaskEither<AppException, HomeBannerEntity> call() => _repository.getHomeBanner();
}

@lazySingleton
class MarkHomeBannerImpressionUseCase {
  final IHomeRepository _repository;

  MarkHomeBannerImpressionUseCase(this._repository);

  /// Fired once per campaign per app session, when a slide actually becomes
  /// visible — see [HomeCubit.trackBannerImpression] for the dedupe. Never
  /// awaited by callers: recording a view is never worth delaying a paint.
  TaskEither<AppException, bool> call(String campaignKey) => _repository.markHomeBannerImpression(campaignKey);
}

@lazySingleton
class MarkHomeBannerClickUseCase {
  final IHomeRepository _repository;

  MarkHomeBannerClickUseCase(this._repository);

  /// Fired when the reader taps a slide, alongside opening its link. Not
  /// awaited by the caller: the link opens immediately either way.
  TaskEither<AppException, bool> call(String campaignKey) => _repository.markHomeBannerClick(campaignKey);
}
