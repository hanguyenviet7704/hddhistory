part of '../../../onboard_v2.dart';

/// Local data source for Onboard V2
///
/// Handles caching of Onboard V2 data for offline support.
/// Note: For paginated APIs, only the items are cached, not pagination metadata.
/// Pagination info (currentPage, totalPages, etc.) should always come fresh from the API.
abstract class OnboardV2LocalDataSource {
  /// Get all cached onboard_v2s
  ///
  /// Used as fallback when API fails. The repository will construct
  /// a BasePageBreak with these items for offline support.
  Future<List<OnboardV2Model>> getCachedOnboardV2s();

  /// Cache multiple onboard_v2s
  ///
  /// For paginated APIs, the repository passes `pageData.items` (not the entire BasePageBreak).
  /// This keeps the cache simple and avoids stale pagination metadata.
  Future<void> cacheOnboardV2s(List<OnboardV2Model> models);

  /// Get cached onboard_v2 by id
  Future<OnboardV2Model?> getCachedOnboardV2(String id);

  /// Cache single onboard_v2
  ///
  /// Used for caching individual items from GET, POST, PUT responses.
  Future<void> cacheOnboardV2(OnboardV2Model model);

  /// Delete cached onboard_v2
  Future<void> deleteCachedOnboardV2(String id);

  /// Clear all cached data
  Future<void> clearCache();
}

@LazySingleton(as: OnboardV2LocalDataSource)
class OnboardV2LocalDataSourceImpl implements OnboardV2LocalDataSource {
  static const String _cacheKey = 'onboard_v2_cache';
  static const String _cacheListKey = 'onboard_v2_list_cache';

  final ILocalStoreService _localStoreService;

  OnboardV2LocalDataSourceImpl(this._localStoreService);

  @override
  Future<List<OnboardV2Model>> getCachedOnboardV2s() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheListKey);
      if (data.isEmpty) return [];

      final List<dynamic> jsonList = data['items'] ?? [];
      return jsonList.map((json) => OnboardV2Model.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheOnboardV2s(List<OnboardV2Model> models) async {
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
  Future<OnboardV2Model?> getCachedOnboardV2(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      final data = await _localStoreService.getMap(key: cacheKey);
      if (data.isEmpty) return null;

      return OnboardV2Model.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheOnboardV2(OnboardV2Model model) async {
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
  Future<void> deleteCachedOnboardV2(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      await _localStoreService.remove(key: cacheKey);

      // Also remove from cached list if exists
      final cachedList = await getCachedOnboardV2s();
      final updatedList = cachedList.where((item) => item.id != id).toList();
      await cacheOnboardV2s(updatedList);
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
