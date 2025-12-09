part of '../../../monetization.dart';

abstract class UserSubscriptionLocalDataSource {
  Future<IapSubscriptionModel?> getCachedUserSubscription(String userId);
  Future<void> cacheUserSubscription(String userId, IapSubscriptionModel model);
  Future<void> clearCache();
  Future<void> cacheProcessedTransactionIds(List<String> ids);
  Future<List<String>> getProcessedTransactionIds();    
}

@LazySingleton(as: UserSubscriptionLocalDataSource)
class UserSubscriptionLocalDataSourceImpl implements UserSubscriptionLocalDataSource {
  static const String _cacheKeyPrefix = 'user_subscription_cache';
  static const String _processedTransactionIdsKey = 'processed_transaction_ids_cache';

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
    } catch (e) {
      LogDev.error('Error caching user subscription: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _localStoreService.remove(key: _cacheKeyPrefix);
    } catch (e) {
      LogDev.error('Error clearing user subscription cache: $e');
    }
  }

  @override
  Future<void> cacheProcessedTransactionIds(List<String> ids) async {
    try {
      await _localStoreService.setList(key: _processedTransactionIdsKey, value: ids);
    } catch (e) {
      LogDev.error('Error caching processed transaction ids: $e');
    }
  }

  @override
  Future<List<String>> getProcessedTransactionIds() async {
    try {
      return await _localStoreService.getList(key: _processedTransactionIdsKey);
    } catch (e) {
      LogDev.error('Error getting processed transaction ids: $e');
      return [];
    }
  }
}
