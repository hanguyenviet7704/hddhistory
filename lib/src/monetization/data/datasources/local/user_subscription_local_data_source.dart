part of '../../../monetization.dart';

abstract class UserSubscriptionLocalDataSource {
  Future<IapSubscriptionModel?> getCachedUserSubscription(String userId);
  Future<void> cacheUserSubscription(String userId, IapSubscriptionModel model);
  Future<void> clearCache();
}

@LazySingleton(as: UserSubscriptionLocalDataSource)
class UserSubscriptionLocalDataSourceImpl implements UserSubscriptionLocalDataSource {
  static const String _cacheKeyPrefix = 'user_subscription_cache';

  final ILocalStoreService _localStoreService;

  UserSubscriptionLocalDataSourceImpl(this._localStoreService);

  @override
  Future<IapSubscriptionModel?> getCachedUserSubscription(String userId) async {
    try {
      final cacheKey = '${_cacheKeyPrefix}_$userId';
      final data = await _localStoreService.getMap(key: cacheKey);
      if (data.isEmpty) return null;
      return IapSubscriptionModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheUserSubscription(String userId, IapSubscriptionModel model) async {
    try {
      final cacheKey = '${_cacheKeyPrefix}_$userId';
      await _localStoreService.setMap(key: cacheKey, value: model.toJson());
    } catch (e) {}
  }

  @override
  Future<void> clearCache() async {
    try {} catch (e) {}
  }
}
