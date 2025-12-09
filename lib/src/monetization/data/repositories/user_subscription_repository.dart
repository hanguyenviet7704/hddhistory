part of '../../monetization.dart';

@LazySingleton(as: IUserSubscriptionRepository)
class UserSubscriptionRepository with RestfulRequestHandlerMixin implements IUserSubscriptionRepository {
  final UserSubscriptionApi _api;
  final UserSubscriptionLocalDataSource _localDataSource;

  UserSubscriptionRepository(this._api, this._localDataSource);

  @override
  TaskEither<AppException, IapSubscriptionEntity> getUserIapSubscriptions(String userId) {
    return callApiWithTransform<IapSubscriptionModel, IapSubscriptionEntity>(
      apiCall: () => _api.getUserIapSubscriptions(userId),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async {
        if (data != null) {
          await _localDataSource.cacheUserSubscription(userId, data);
        }
      },
      onError: () async {
        final cachedModel = await _localDataSource.getCachedUserSubscription(userId);
        return cachedModel?.toEntity();
      },
      defaultValue: IapSubscriptionEntity(),
    );
  }
}
