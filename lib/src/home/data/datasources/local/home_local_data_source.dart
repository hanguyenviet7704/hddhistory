part of '../../../home.dart';

/// Local data source for Home
///
/// Handles caching of Skillset data for offline support.
/// Note: For paginated APIs, only the items are cached, not pagination metadata.
/// Pagination info (currentPage, totalPages, etc.) should always come fresh from the API.
abstract class HomeLocalDataSource {
  /// Get all cached skillsets
  ///
  /// Used as fallback when API fails. The repository will construct
  /// a BasePageBreak with these items for offline support.
  Future<List<SkillsetModel>> getCachedSkillsets();

  /// Cache multiple skillsets
  ///
  /// For paginated APIs, the repository passes `pageData.items` (not the entire BasePageBreak).
  /// This keeps the cache simple and avoids stale pagination metadata.
  Future<void> cacheSkillsets(List<SkillsetModel> models);

  /// Get cached skillset by id
  Future<SkillsetModel?> getCachedSkillset(String id);

  /// Cache single skillset
  ///
  /// Used for caching individual items from GET, POST, PUT responses.
  Future<void> cacheSkillset(SkillsetModel model);

  /// Delete cached skillset
  Future<void> deleteCachedSkillset(String id);

  /// Clear all cached data
  Future<void> clearCache();
}

@LazySingleton(as: HomeLocalDataSource)
class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  static const String _cacheKey = 'home_cache';
  static const String _cacheListKey = 'home_list_cache';

  final ILocalStoreService _localStoreService;

  HomeLocalDataSourceImpl(this._localStoreService);

  @override
  Future<List<SkillsetModel>> getCachedSkillsets() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheListKey);
      if (data.isEmpty) return [];

      final List<dynamic> jsonList = data['items'] ?? [];
      return jsonList
          .map((json) => SkillsetModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheSkillsets(List<SkillsetModel> models) async {
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
  Future<SkillsetModel?> getCachedSkillset(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      final data = await _localStoreService.getMap(key: cacheKey);
      if (data.isEmpty) return null;

      return SkillsetModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheSkillset(SkillsetModel model) async {
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
  Future<void> deleteCachedSkillset(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      await _localStoreService.remove(key: cacheKey);

      // Also remove from cached list if exists
      final cachedList = await getCachedSkillsets();
      final updatedList = cachedList.where((item) => item.id != id).toList();
      await cacheSkillsets(updatedList);
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
