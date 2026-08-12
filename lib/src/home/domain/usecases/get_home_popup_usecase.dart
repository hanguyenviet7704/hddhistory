part of '../../home.dart';

@lazySingleton
class GetHomePopupUseCase {
  final IHomeRepository _repository;

  GetHomePopupUseCase(this._repository);

  TaskEither<AppException, HomePopupEntity> call() => _repository.getHomePopup();
}

@lazySingleton
class MarkHomePopupClickedUseCase {
  final IHomeRepository _repository;

  MarkHomePopupClickedUseCase(this._repository);

  /// Fired when the reader taps the popup, and deliberately not awaited by the
  /// caller: the link opens immediately either way. A failure here only costs the
  /// popup coming back next session, where tapping again retries it.
  TaskEither<AppException, bool> call(String campaignKey) => _repository.markHomePopupClicked(campaignKey);
}
