part of '../../../daily_warm_up.dart';

abstract class DailyWarmUpLocalDataSource {
  Future<DailyWarmUpModel?> getCachedDailyWarmUp();
  Future<void> cacheDailyWarmUp(DailyWarmUpModel model);
  Future<void> clearCache();
}

@LazySingleton(as: DailyWarmUpLocalDataSource)
class DailyWarmUpLocalDataSourceImpl implements DailyWarmUpLocalDataSource {
  static const String _cacheKey = 'daily_warm_up_cache';

  final ILocalStoreService _localStoreService;

  DailyWarmUpLocalDataSourceImpl(this._localStoreService);

  @override
  Future<DailyWarmUpModel?> getCachedDailyWarmUp() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheKey);
      if (data.isEmpty) return null;
      return DailyWarmUpModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheDailyWarmUp(DailyWarmUpModel model) async {
    try {
      await _localStoreService.setMap(key: _cacheKey, value: model.toJson());
    } catch (e) {
      LogDev.error('Error caching daily warm up: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _localStoreService.remove(key: _cacheKey);
    } catch (e) {
      LogDev.error('Error clearing daily warm up cache: $e');
    }
  }
}
