part of '../../onboard.dart';

@LazySingleton(as: IOnboardRepository)
class OnboardRepository with RestfulRequestHandlerMixin implements IOnboardRepository {
  final OnboardApi _api;
  final OnboardLocalDataSource _localDataSource;

  OnboardRepository(this._api, this._localDataSource);

  @override
  TaskEither<AppException, OnboardEntity> getAllOnboards() {
    return callApiWithTransform<OnboardModel, OnboardEntity>(
      apiCall: () => _api.getAllOnboard(),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheOnboard(data ?? OnboardModel()),
      onError: () async {
        final cachedModel = await _localDataSource.getCachedOnboard('');
        return cachedModel?.toEntity();
      },
      defaultValue: OnboardEntity(),
    );
  }

  @override
  TaskEither<AppException, UserEntity> getUserByDeviceId(String deviceId) {
    return callApiWithTransform<UserModel, UserEntity>(
      apiCall: () => _api.getUserByDeviceId(deviceId),
      transform: (model) => model.toEntity(),
      defaultValue: UserEntity(),
      enableErrorMessages: false,
    );
  }
}
