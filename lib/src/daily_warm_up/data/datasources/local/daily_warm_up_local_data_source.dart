part of '../../../daily_warm_up.dart';

/// Local data source for Daily Warm Up
///
/// Handles caching of Daily Warm Up data for offline support.
/// Note: For paginated APIs, only the items are cached, not pagination metadata.
/// Pagination info (currentPage, totalPages, etc.) should always come fresh from the API.
abstract class DailyWarmUpLocalDataSource {
  /// Get all cached daily_warm_ups
  ///
  /// Used as fallback when API fails. The repository will construct
  /// a BasePageBreak with these items for offline support.
  Future<List<DailyWarmUpModel>> getCachedDailyWarmUps();

  /// Cache multiple daily_warm_ups
  ///
  /// For paginated APIs, the repository passes `pageData.items` (not the entire BasePageBreak).
  /// This keeps the cache simple and avoids stale pagination metadata.
  Future<void> cacheDailyWarmUps(List<DailyWarmUpModel> models);

  /// Get cached daily_warm_up by id
  Future<DailyWarmUpModel?> getCachedDailyWarmUp(String id);

  /// Cache single daily_warm_up
  ///
  /// Used for caching individual items from GET, POST, PUT responses.
  Future<void> cacheDailyWarmUp(DailyWarmUpModel model);

  /// Delete cached daily_warm_up
  Future<void> deleteCachedDailyWarmUp(String id);

  /// Clear all cached data
  Future<void> clearCache();
}

@LazySingleton(as: DailyWarmUpLocalDataSource)
class DailyWarmUpLocalDataSourceImpl implements DailyWarmUpLocalDataSource {
  static const String _cacheKey = 'daily_warm_up_cache';
  static const String _cacheListKey = 'daily_warm_up_list_cache';

  final ILocalStoreService _localStoreService;

  DailyWarmUpLocalDataSourceImpl(this._localStoreService);

  @override
  Future<List<DailyWarmUpModel>> getCachedDailyWarmUps() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheListKey);
      if (data.isEmpty) return [];

      final List<dynamic> jsonList = data['items'] ?? [];
      return jsonList
          .map((json) => DailyWarmUpModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheDailyWarmUps(List<DailyWarmUpModel> models) async {
    try {
      final jsonList = models.map((model) => model.toJson()).toList();
      await _localStoreService.setMap(
        key: _cacheListKey,
        value: {'items': jsonList},
      );
    } catch (e) {
      // Handle error silently or log
    }
  }

  @override
  Future<DailyWarmUpModel?> getCachedDailyWarmUp(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      final data = await _localStoreService.getMap(key: cacheKey);
      if (data.isEmpty) return null;

      return DailyWarmUpModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheDailyWarmUp(DailyWarmUpModel model) async {
    try {
      final cacheKey = '${_cacheKey}_${model.id}';
      await _localStoreService.setMap(
        key: cacheKey,
        value: model.toJson(),
      );
    } catch (e) {
      // Handle error silently or log
    }
  }

  @override
  Future<void> deleteCachedDailyWarmUp(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      await _localStoreService.remove(key: cacheKey);

      // Also remove from cached list if exists
      final cachedList = await getCachedDailyWarmUps();
      final updatedList = cachedList.where((item) => item.id != id).toList();
      await cacheDailyWarmUps(updatedList);
    } catch (e) {
      // Handle error silently or log
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _localStoreService.remove(key: _cacheListKey);
      // Note: Individual item caches (_cacheKey_id) are kept for specific item lookups
      // To clear everything, you could track all keys or implement prefix-based deletion
    } catch (e) {
      // Handle error silently or log
    }
  }
}

